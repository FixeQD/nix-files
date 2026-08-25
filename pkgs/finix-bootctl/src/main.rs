//! finix-bootctl - manage Finix EFISTUB boot entries through the `efivar` and `gpt` crates instead of shelling out to efibootmgr/blkid/lsblk

use std::env;
use std::fs;
use std::path::Path;
use std::process::ExitCode;

use efivar::boot::{EFIHardDrive, EFIHardDriveType};
use efivar::efi::Variable;
use efivar::{Error as EfiError, VarManager};
use eros::Context;

pub mod testtoolkit;
use testtoolkit::{die, list_generations, parse_mountinfo_from_str};

fn try_parse_mountinfo() -> eros::Result<Vec<testtoolkit::MountEntry>> {
    let content = fs::read_to_string("/proc/self/mountinfo").context("reading /proc/self/mountinfo")?;
    Ok(parse_mountinfo_from_str(&content))
}

fn parse_mountinfo() -> Vec<testtoolkit::MountEntry> {
    try_parse_mountinfo().unwrap_or_else(|e| die(format!("{e}")))
}

fn try_resolve_partition(mount_point: &Path) -> eros::Result<(String, u32)> {
    let canon = fs::canonicalize(mount_point).with_context(|| format!("resolving {}", mount_point.display()))?;

    let entry = try_parse_mountinfo()?
        .into_iter()
        .find(|e| {
            fs::canonicalize(&e.mount_point)
                .map(|p| p == canon)
                .unwrap_or(false)
        })
        .ok_or_else(|| eros::error!("no mount found for {}", mount_point.display()))?;

    let sys_link = format!("/sys/dev/block/{}:{}", entry.major, entry.minor);
    let target = fs::read_link(&sys_link).with_context(|| format!("reading {sys_link}"))?;

    let part_name = target
        .file_name()
        .ok_or_else(|| eros::error!("malformed sysfs block symlink at {sys_link}"))?
        .to_string_lossy()
        .into_owned();

    let disk_name = target
        .parent()
        .and_then(|p| p.file_name())
        .ok_or_else(|| eros::error!("malformed sysfs block symlink at {sys_link} (no parent)"))?
        .to_string_lossy()
        .into_owned();

    let partition_number: u32 = fs::read_to_string(format!("/sys/class/block/{part_name}/partition"))
        .with_context(|| format!("reading partition number for {part_name}"))?
        .trim()
        .parse::<u32>()
        .with_context(|| format!("parsing partition number for {part_name}"))?;

    Ok((disk_name, partition_number))
}

fn resolve_partition(mount_point: &Path) -> (String, u32) {
    try_resolve_partition(mount_point).unwrap_or_else(|e| die(format!("{e}")))
}

fn try_read_logical_block_size(disk_name: &str) -> eros::Result<gpt::disk::LogicalBlockSize> {
    let raw: u64 = fs::read_to_string(format!("/sys/block/{disk_name}/queue/logical_block_size"))
        .with_context(|| format!("reading logical_block_size for {disk_name}"))?
        .trim()
        .parse::<u64>()
        .with_context(|| format!("parsing logical_block_size for {disk_name}"))?;

    raw.try_into()
        .map_err(|_| eros::error!("unsupported logical block size {raw} on {disk_name}"))
}

fn read_logical_block_size(disk_name: &str) -> gpt::disk::LogicalBlockSize {
    try_read_logical_block_size(disk_name).unwrap_or_else(|e| die(format!("{e}")))
}

fn try_build_hard_drive(esp_mount_point: &Path) -> eros::Result<EFIHardDrive> {
    let (disk_name, partition_number) = try_resolve_partition(esp_mount_point)?;
    let lb_size = try_read_logical_block_size(&disk_name)?;

    let disk_path = format!("/dev/{disk_name}");
    let disk = gpt::GptConfig::new()
        .writable(false)
        .logical_block_size(lb_size)
        .open(&disk_path)
        .with_context(|| format!("reading GPT table on {disk_path}"))?;

    let part = disk
        .partitions()
        .get(&partition_number)
        .ok_or_else(|| eros::error!("partition {partition_number} not found in GPT table on {disk_path}"))?;

    Ok(EFIHardDrive {
        partition_number,
        partition_start: part.first_lba,
        partition_size: part.last_lba - part.first_lba + 1,
        partition_sig: part.part_guid,
        format: 0x02,
        sig_type: EFIHardDriveType::Gpt,
    })
}

fn build_hard_drive(esp_mount_point: &Path) -> EFIHardDrive {
    try_build_hard_drive(esp_mount_point).unwrap_or_else(|e| die(format!("{e}")))
}

fn try_cmd_list(mgr: &dyn VarManager) -> eros::Result<()> {
    for g in testtoolkit::try_list_generations(mgr)? {
        println!("{:04X} {}", g.id, g.ts);
    }
    Ok(())
}

fn cmd_list(mgr: &dyn VarManager) {
    try_cmd_list(mgr).unwrap_or_else(|e| die(format!("{e}")))
}

fn try_cmd_create(
    mgr: &mut dyn VarManager,
    esp_mount_point: &str,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) -> eros::Result<u16> {
    let hard_drive = try_build_hard_drive(Path::new(esp_mount_point))?;
    Ok(testtoolkit::try_cmd_create_with_hard_drive(
        mgr, hard_drive, loader_path, optional_data, timestamp,
    )?)
}

fn cmd_create(
    mgr: &mut dyn VarManager,
    esp_mount_point: &str,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) {
    let id = try_cmd_create(mgr, esp_mount_point, loader_path, optional_data, timestamp)
        .unwrap_or_else(|e| die(format!("{e}")));
    println!("{id:04X}");
}

fn try_cmd_delete(mgr: &mut dyn VarManager, id: u16) -> eros::Result<()> {
    mgr.delete(&Variable::new(&format!("Boot{id:04X}")))
        .with_context(|| format!("deleting Boot{id:04X}"))?;

    let mut order = match mgr.get_boot_order() {
        Ok(order) => order,
        Err(EfiError::VarNotFound { .. }) => Vec::new(),
        Err(e) => return Err(eros::error!(e).context("reading BootOrder")),
    };

    let before = order.len();
    order.retain(|&x| x != id);
    if order.len() != before {
        mgr.set_boot_order(order).context("writing BootOrder")?;
    }
    Ok(())
}

fn cmd_delete(mgr: &mut dyn VarManager, id: u16) {
    try_cmd_delete(mgr, id).unwrap_or_else(|e| die(format!("{e}")))
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

    let res: eros::Result<()> = (|| {
        match args[1].as_str() {
            "list" => try_cmd_list(mgr.as_ref())?,
            "create" => {
                if args.len() != 6 {
                    usage(&args[0]);
                }
                let timestamp: i64 = args[5]
                    .parse::<i64>()
                    .map_err(|e| eros::error!(e).context(format!("parsing timestamp {:?} as i64", args[5])))?;
                try_cmd_create(mgr.as_mut(), &args[2], &args[3], &args[4], timestamp)?;
            }
            "delete" => {
                if args.len() != 3 {
                    usage(&args[0]);
                }
                let id = u16::from_str_radix(&args[2], 16)
                    .map_err(|e| eros::error!(e).context(format!("parsing Boot id {:?} as hex u16", args[2])))?;
                try_cmd_delete(mgr.as_mut(), id)?;
            }
            _ => usage(&args[0]),
        }
        Ok(())
    })();

    if let Err(e) = res {
        eprintln!("finix-bootctl: {e}");
        if std::env::var("RUST_BACKTRACE").is_ok() {
            eprintln!("{e:?}");
        }
        return ExitCode::from(1);
    }

    ExitCode::SUCCESS
}
