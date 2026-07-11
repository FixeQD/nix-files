//! finix-bootctl - manage Finix EFISTUB boot entries through the `efivar` and `gpt` crates instead of shelling out to efibootmgr/blkid/lsblk

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use efivar::boot::{
    BootEntry, BootEntryAttributes, EFIHardDrive, EFIHardDriveType, FilePath, FilePathList,
};
use efivar::efi::Variable;
use efivar::{Error as EfiError, VarManager};

const DESC_PREFIX: &str = "Finix";

fn die(msg: impl std::fmt::Display) -> ! {
    eprintln!("finix-bootctl: {msg}");
    std::process::exit(1);
}

fn finix_timestamp(description: &str) -> Option<i64> {
    description.strip_prefix(DESC_PREFIX)?.trim().parse().ok()
}

struct MountEntry {
    mount_point: PathBuf,
    major: u32,
    minor: u32,
}

fn parse_mountinfo() -> Vec<MountEntry> {
    let content = fs::read_to_string("/proc/self/mountinfo")
        .unwrap_or_else(|e| die(format!("reading /proc/self/mountinfo: {e}")));

    content
        .lines()
        .filter_map(|line| {
            // Format: id parent major:minor root mount_point opts... - fstype source super_opts
            let (pre, _post) = line.split_once(" - ")?;
            let fields: Vec<&str> = pre.split(' ').collect();
            let majmin = fields.get(2)?;
            let (major, minor) = majmin.split_once(':')?;
            Some(MountEntry {
                mount_point: PathBuf::from(*fields.get(4)?),
                major: major.parse().ok()?,
                minor: minor.parse().ok()?,
            })
        })
        .collect()
}

fn resolve_partition(mount_point: &Path) -> (String, u32) {
    let canon = fs::canonicalize(mount_point)
        .unwrap_or_else(|e| die(format!("resolving {}: {e}", mount_point.display())));

    let entry = parse_mountinfo()
        .into_iter()
        .find(|e| {
            fs::canonicalize(&e.mount_point)
                .map(|p| p == canon)
                .unwrap_or(false)
        })
        .unwrap_or_else(|| die(format!("no mount found for {}", mount_point.display())));

    let sys_link = format!("/sys/dev/block/{}:{}", entry.major, entry.minor);
    let target = fs::read_link(&sys_link)
        .unwrap_or_else(|e| die(format!("reading {sys_link}: {e}")));

    let part_name = target
        .file_name()
        .unwrap_or_else(|| die(format!("malformed sysfs block symlink at {sys_link}")))
        .to_string_lossy()
        .into_owned();

    let disk_name = target
        .parent()
        .and_then(|p| p.file_name())
        .unwrap_or_else(|| die(format!("malformed sysfs block symlink at {sys_link} (no parent)")))
        .to_string_lossy()
        .into_owned();

    let partition_number: u32 =
        fs::read_to_string(format!("/sys/class/block/{part_name}/partition"))
            .unwrap_or_else(|e| die(format!("reading partition number for {part_name}: {e}")))
            .trim()
            .parse()
            .unwrap_or_else(|e| die(format!("parsing partition number for {part_name}: {e}")));

    (disk_name, partition_number)
}

fn read_logical_block_size(disk_name: &str) -> gpt::disk::LogicalBlockSize {
    let raw: u64 = fs::read_to_string(format!(
        "/sys/block/{disk_name}/queue/logical_block_size"
    ))
    .unwrap_or_else(|e| die(format!("reading logical_block_size for {disk_name}: {e}")))
    .trim()
    .parse()
    .unwrap_or_else(|e| die(format!("parsing logical_block_size for {disk_name}: {e}")));

    raw.try_into()
        .unwrap_or_else(|_| die(format!("unsupported logical block size {raw} on {disk_name}")))
}

fn build_hard_drive(esp_mount_point: &Path) -> EFIHardDrive {
    let (disk_name, partition_number) = resolve_partition(esp_mount_point);
    let lb_size = read_logical_block_size(&disk_name);

    let disk_path = format!("/dev/{disk_name}");
    let disk = gpt::GptConfig::new()
        .writable(false)
        .logical_block_size(lb_size)
        .open(&disk_path)
        .unwrap_or_else(|e| die(format!("reading GPT table on {disk_path}: {e}")));

    let part = disk.partitions().get(&partition_number).unwrap_or_else(|| {
        die(format!(
            "partition {partition_number} not found in GPT table on {disk_path}"
        ))
    });

    EFIHardDrive {
        partition_number,
        partition_start: part.first_lba,
        partition_size: part.last_lba - part.first_lba + 1,
        partition_sig: part.part_guid,
        format: 0x02, // GPT
        sig_type: EFIHardDriveType::Gpt,
    }
}

struct Generation {
    id: u16,
    ts: i64,
}

fn list_generations(mgr: &dyn VarManager) -> Vec<Generation> {
    let mut gens: Vec<Generation> = mgr
        .get_boot_entries()
        .unwrap_or_else(|e| die(format!("reading boot entries: {e}")))
        .filter_map(|(res, var)| match res {
            Ok(bv) => {
                let ts = finix_timestamp(&bv.entry.description)?;
                Some(Generation { id: bv.id, ts })
            }
            Err(e) => {
                eprintln!("finix-bootctl: warning: failed to parse boot entry {var:?}: {e}");
                None
            }
        })
        .collect();

    gens.sort_by_key(|b| std::cmp::Reverse(b.ts));
    gens
}

fn cmd_list(mgr: &dyn VarManager) {
    for g in list_generations(mgr) {
        println!("{:04X} {}", g.id, g.ts);
    }
}

fn find_free_id(mgr: &dyn VarManager) -> u16 {
    for id in 0u16..=0xFFFF {
        let var = Variable::new(&format!("Boot{id:04X}"));
        match mgr.exists(&var) {
            Ok(false) => return id,
            Ok(true) => continue,
            Err(e) => die(format!("checking Boot{id:04X}: {e}")),
        }
    }
    die("no free Boot#### slot left")
}

fn cmd_create(
    mgr: &mut dyn VarManager,
    esp_mount_point: &str,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) {
    let hard_drive = build_hard_drive(Path::new(esp_mount_point));

    let entry = BootEntry {
        attributes: BootEntryAttributes::LOAD_OPTION_ACTIVE,
        description: format!("{DESC_PREFIX}{timestamp}"),
        file_path_list: Some(FilePathList {
            file_path: FilePath {
                path: loader_path.to_string(),
            },
            hard_drive,
        }),
        optional_data: optional_data
            .encode_utf16()
            .flat_map(|c| c.to_le_bytes())
            .collect(),
    };

    let id = find_free_id(&*mgr);

    mgr.add_boot_entry(id, entry)
        .unwrap_or_else(|e| die(format!("creating boot entry Boot{id:04X}: {e}")));

    let mut order = match mgr.get_boot_order() {
        Ok(order) => order,
        Err(EfiError::VarNotFound { .. }) => Vec::new(),
        Err(e) => die(format!("reading BootOrder: {e}")),
    };
    order.retain(|&x| x != id);
    order.insert(0, id);
    mgr.set_boot_order(order)
        .unwrap_or_else(|e| die(format!("writing BootOrder: {e}")));

    println!("{id:04X}");
}

fn cmd_delete(mgr: &mut dyn VarManager, id: u16) {
    if let Err(e) = mgr.delete(&Variable::new(&format!("Boot{id:04X}"))) {
        die(format!("deleting Boot{id:04X}: {e}"));
    }

    let mut order = match mgr.get_boot_order() {
        Ok(order) => order,
        Err(EfiError::VarNotFound { .. }) => Vec::new(),
        Err(e) => die(format!("reading BootOrder: {e}")),
    };

    let before = order.len();
    order.retain(|&x| x != id);
    if order.len() != before {
        mgr.set_boot_order(order)
            .unwrap_or_else(|e| die(format!("writing BootOrder: {e}")));
    }
}

fn usage(prog: &str) -> ! {
    eprintln!("usage: {prog} list");
    eprintln!(
        "       {prog} create <esp-mount-point> <loader-path-on-esp> <optional-data> <timestamp>"
    );
    eprintln!("       {prog} delete <num-hex>");
    std::process::exit(2);
}

fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        usage(&args[0]);
    }

    let mut mgr = efivar::system();

    match args[1].as_str() {
        "list" => cmd_list(mgr.as_ref()),
        "create" => {
            if args.len() != 6 {
                usage(&args[0]);
            }
            let timestamp: i64 = args[5].parse().unwrap_or_else(|_| usage(&args[0]));
            cmd_create(mgr.as_mut(), &args[2], &args[3], &args[4], timestamp);
        }
        "delete" => {
            if args.len() != 3 {
                usage(&args[0]);
            }
            let id = u16::from_str_radix(&args[2], 16).unwrap_or_else(|_| usage(&args[0]));
            cmd_delete(mgr.as_mut(), id);
        }
        _ => usage(&args[0]),
    }

    ExitCode::SUCCESS
}
