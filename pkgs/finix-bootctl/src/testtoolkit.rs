//! testtoolkit - helpers for NVRAM / boot simulation
//! Extracted from `main.rs` (`finix_timestamp`, `parse_mountinfo_from_str`, `list_generations`, etc.)
//! and `EFIHardDrive` factories / firmware simulators.
//! Used by `crate::tests` via `crate::testtoolkit`.

use std::path::PathBuf;

use efivar::boot::{
    BootEntry, BootEntryAttributes, BootVarReader, BootVarWriter, EFIHardDrive, EFIHardDriveType,
    FilePath, FilePathList,
};
use efivar::efi::Variable;
use efivar::store::MemoryStore;
use efivar::{Error as EfiError, VarManager};
use uuid::Uuid;

pub const DESC_PREFIX: &str = "Finix";

pub fn die(msg: impl std::fmt::Display) -> ! {
    eprintln!("finix-bootctl: {msg}");
    std::process::exit(1);
}

pub fn finix_timestamp(description: &str) -> Option<i64> {
    let rest = description.strip_prefix(DESC_PREFIX)?;
    match rest.trim().parse() {
        Ok(ts) => Some(ts),
        Err(e) => {
            eprintln!(
                "finix-bootctl: warning: entry {DESC_PREFIX:?}-prefixed but unparsable timestamp {rest:?}: {e}"
            );
            None
        }
    }
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct MountEntry {
    pub mount_point: PathBuf,
    pub major: u32,
    pub minor: u32,
}

/// Parse mountinfo content into entries.
pub fn parse_mountinfo_from_str(content: &str) -> Vec<MountEntry> {
    content
        .lines()
        .filter_map(|line| {
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

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct Generation {
    pub id: u16,
    pub ts: i64,
}

pub fn list_generations(mgr: &dyn VarManager) -> Vec<Generation> {
    let mut gens: Vec<Generation> = mgr
        .get_all_vars()
        .unwrap_or_else(|e| die(format!("enumerating NVRAM variables: {e}")))
        .filter_map(|var| {
            let id = var.boot_var_id()?;
            match BootEntry::read(mgr, &var) {
                Ok(entry) => {
                    let ts = finix_timestamp(&entry.description)?;
                    Some(Generation { id, ts })
                }
                Err(e) => {
                    eprintln!("finix-bootctl: warning: failed to parse boot entry {var:?}: {e}");
                    None
                }
            }
        })
        .collect();

    gens.sort_by_key(|b| std::cmp::Reverse(b.ts));
    gens
}

/// Format generations without printing.
pub fn list_generations_formatted(mgr: &dyn VarManager) -> Vec<String> {
    list_generations(mgr)
        .into_iter()
        .map(|g| format!("{:04X} {}", g.id, g.ts))
        .collect()
}

pub fn find_free_id(mgr: &dyn VarManager) -> u16 {
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

/// Build BootEntry without disk access.
pub fn build_boot_entry(
    hard_drive: EFIHardDrive,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) -> BootEntry {
    BootEntry {
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
    }
}

/// Create logic using injected EFIHardDrive.
pub fn cmd_create_with_hard_drive(
    mgr: &mut dyn VarManager,
    hard_drive: EFIHardDrive,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) -> u16 {
    let entry = build_boot_entry(hard_drive, loader_path, optional_data, timestamp);
    let id = find_free_id(&*mgr);
    mgr.add_boot_entry(id, entry)
        .unwrap_or_else(|e| die(format!("creating boot entry Boot{id:04X}: {e}")));

    let known_finix_ids: Vec<u16> = list_generations(&*mgr).into_iter().map(|g| g.id).collect();

    let mut order = match mgr.get_boot_order() {
        Ok(order) => order,
        Err(EfiError::VarNotFound { .. }) => Vec::new(),
        Err(e) => die(format!("reading BootOrder: {e}")),
    };
    order.retain(|x| !known_finix_ids.contains(x));
    order.splice(0..0, known_finix_ids);
    mgr.set_boot_order(order)
        .unwrap_or_else(|e| die(format!("writing BootOrder: {e}")));

    id
}

// Mock / simulation helpers - NVRAM / boot (MemoryStore)

/// Dummy GPT disk - deterministic UUID and LBA params, format 0x02 / Gpt.
pub fn dummy_hard_drive(partition_number: u32) -> EFIHardDrive {
    EFIHardDrive {
        partition_number,
        partition_start: 2048 + (partition_number as u64 * 1000),
        partition_size: 100_000,
        partition_sig: Uuid::parse_str("12345678-1234-1234-1234-123456789abc").unwrap(),
        format: 0x02,
        sig_type: EFIHardDriveType::Gpt,
    }
}

pub fn dummy_hard_drive_with_sig(partition_number: u32, sig: Uuid) -> EFIHardDrive {
    EFIHardDrive {
        partition_number,
        partition_start: 2048,
        partition_size: 50000,
        partition_sig: sig,
        format: 0x02,
        sig_type: EFIHardDriveType::Gpt,
    }
}

pub fn make_finix_entry(ts: i64, partition_number: u32, loader: &str, optional: &str) -> BootEntry {
    BootEntry {
        attributes: BootEntryAttributes::LOAD_OPTION_ACTIVE,
        description: format!("Finix{ts}"),
        file_path_list: Some(FilePathList {
            file_path: FilePath {
                path: loader.to_string(),
            },
            hard_drive: dummy_hard_drive(partition_number),
        }),
        optional_data: optional
            .encode_utf16()
            .flat_map(|c| c.to_le_bytes())
            .collect(),
    }
}

pub fn insert_finix(mgr: &mut MemoryStore, id: u16, ts: i64) {
    let entry = make_finix_entry(ts, 1, "\\EFI\\Finix\\bootx64.efi", "");
    mgr.add_boot_entry(id, entry).unwrap();
}

pub fn insert_finix_with_loader(
    mgr: &mut MemoryStore,
    id: u16,
    ts: i64,
    loader: &str,
    optional: &str,
) {
    let entry = make_finix_entry(ts, 1, loader, optional);
    mgr.add_boot_entry(id, entry).unwrap();
}

pub fn insert_non_finix(mgr: &mut MemoryStore, id: u16, desc: &str) {
    let entry = BootEntry {
        attributes: BootEntryAttributes::LOAD_OPTION_ACTIVE,
        description: desc.to_string(),
        file_path_list: Some(FilePathList {
            file_path: FilePath {
                path: "\\EFI\\Other\\boot.efi".to_string(),
            },
            hard_drive: dummy_hard_drive(1),
        }),
        optional_data: vec![],
    };
    mgr.add_boot_entry(id, entry).unwrap();
}

pub fn boot_order(mgr: &MemoryStore) -> Vec<u16> {
    mgr.get_boot_order().unwrap_or_default()
}

pub fn set_boot_order(mgr: &mut MemoryStore, order: Vec<u16>) {
    mgr.set_boot_order(order).unwrap();
}

/// Simulate UEFI firmware selection: iterate `BootOrder`, return first `BootEntry`
/// that exists and has `LOAD_OPTION_ACTIVE`.
pub fn simulate_boot(mgr: &dyn VarManager) -> Option<(u16, BootEntry)> {
    let order = match mgr.get_boot_order() {
        Ok(o) => o,
        Err(_) => return None,
    };
    for id in order {
        let var = Variable::new(&format!("Boot{id:04X}"));
        if let Ok(entry) = BootEntry::read(mgr, &var) {
            if entry
                .attributes
                .contains(BootEntryAttributes::LOAD_OPTION_ACTIVE)
            {
                return Some((id, entry));
            }
        }
    }
    None
}

/// Simulate Finix-aware selection: pick newest generation from `list_generations`.
pub fn simulate_finix_boot(mgr: &dyn VarManager) -> Option<(u16, i64)> {
    let gens = list_generations(mgr);
    gens.into_iter().next().map(|g: Generation| (g.id, g.ts))
}

// Workaround: tests outside `src/` - `tests/` next to `src/`
#[cfg(test)]
#[path = "../tests/mod.rs"]
mod tests;
