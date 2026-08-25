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
use eros::Context;
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
    try_list_generations(mgr).unwrap_or_else(|e| die(format!("enumerating NVRAM variables: {e}")))
}

pub fn try_list_generations(mgr: &dyn VarManager) -> eros::Result<Vec<Generation>> {
    let vars = mgr.get_all_vars().context("enumerating NVRAM variables")?;
    let mut gens: Vec<Generation> = vars
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
    Ok(gens)
}

/// Format generations without printing.
pub fn list_generations_formatted(mgr: &dyn VarManager) -> Vec<String> {
    try_list_generations_formatted(mgr)
        .unwrap_or_else(|e| die(format!("formatting generations: {e}")))
}

pub fn try_list_generations_formatted(mgr: &dyn VarManager) -> eros::Result<Vec<String>> {
    Ok(try_list_generations(mgr)?
        .into_iter()
        .map(|g| format!("{:04X} {}", g.id, g.ts))
        .collect())
}

pub fn find_free_id(mgr: &dyn VarManager) -> u16 {
    try_find_free_id(mgr).unwrap_or_else(|e| die(format!("finding free id: {e}")))
}

pub fn try_find_free_id(mgr: &dyn VarManager) -> eros::Result<u16> {
    for id in 0u16..=0xFFFF {
        let var = Variable::new(&format!("Boot{id:04X}"));
        let exists = mgr
            .exists(&var)
            .with_context(|| format!("checking Boot{id:04X}"))?;
        if !exists {
            return Ok(id);
        }
    }
    Err(eros::error!("no free Boot#### slot left"))
}

/// Build BootEntry without disk access.
pub fn build_boot_entry(
    hard_drive: EFIHardDrive,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) -> BootEntry {
    try_build_boot_entry(hard_drive, loader_path, optional_data, timestamp)
        .unwrap_or_else(|e| die(format!("building boot entry: {e}")))
}

pub fn try_build_boot_entry(
    hard_drive: EFIHardDrive,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) -> eros::Result<BootEntry> {
    if loader_path.is_empty() {
        return Err(eros::error!("loader_path must not be empty"));
    }
    Ok(BootEntry {
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
    })
}

/// Create logic using injected EFIHardDrive.
pub fn cmd_create_with_hard_drive(
    mgr: &mut dyn VarManager,
    hard_drive: EFIHardDrive,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) -> u16 {
    try_cmd_create_with_hard_drive(mgr, hard_drive, loader_path, optional_data, timestamp)
        .unwrap_or_else(|e| die(format!("creating boot entry: {e}")))
}

pub fn try_cmd_create_with_hard_drive(
    mgr: &mut dyn VarManager,
    hard_drive: EFIHardDrive,
    loader_path: &str,
    optional_data: &str,
    timestamp: i64,
) -> eros::Result<u16> {
    let entry = try_build_boot_entry(hard_drive, loader_path, optional_data, timestamp)?;
    let id = try_find_free_id(&*mgr)?;
    mgr.add_boot_entry(id, entry)
        .with_context(|| format!("creating boot entry Boot{id:04X}"))?;

    let known_finix_ids: Vec<u16> = try_list_generations(&*mgr)?
        .into_iter()
        .map(|g| g.id)
        .collect();

    let mut order = match mgr.get_boot_order() {
        Ok(order) => order,
        Err(EfiError::VarNotFound { .. }) => Vec::new(),
        Err(e) => return Err(eros::error!(e).context("reading BootOrder")),
    };
    order.retain(|x| !known_finix_ids.contains(x));
    order.splice(0..0, known_finix_ids);
    mgr.set_boot_order(order).context("writing BootOrder")?;

    Ok(id)
}

// Mock / simulation helpers - NVRAM / boot (MemoryStore)

pub fn try_dummy_hard_drive(partition_number: u32) -> eros::Result<EFIHardDrive> {
    let sig =
        Uuid::parse_str("12345678-1234-1234-1234-123456789abc").context("parsing dummy UUID")?;
    Ok(EFIHardDrive {
        partition_number,
        partition_start: 2048 + (partition_number as u64 * 1000),
        partition_size: 100_000,
        partition_sig: sig,
        format: 0x02,
        sig_type: EFIHardDriveType::Gpt,
    })
}

pub fn dummy_hard_drive(partition_number: u32) -> EFIHardDrive {
    try_dummy_hard_drive(partition_number).unwrap_or_else(|e| die(format!("dummy_hard_drive: {e}")))
}

pub fn try_dummy_hard_drive_with_sig(
    partition_number: u32,
    sig: Uuid,
) -> eros::Result<EFIHardDrive> {
    if sig.is_nil() {
        return Err(eros::error!("partition sig must not be nil"));
    }
    Ok(EFIHardDrive {
        partition_number,
        partition_start: 2048,
        partition_size: 50000,
        partition_sig: sig,
        format: 0x02,
        sig_type: EFIHardDriveType::Gpt,
    })
}

pub fn dummy_hard_drive_with_sig(partition_number: u32, sig: Uuid) -> EFIHardDrive {
    try_dummy_hard_drive_with_sig(partition_number, sig)
        .unwrap_or_else(|e| die(format!("dummy_hard_drive_with_sig: {e}")))
}

pub fn try_make_finix_entry(
    ts: i64,
    partition_number: u32,
    loader: &str,
    optional: &str,
) -> eros::Result<BootEntry> {
    let hd = try_dummy_hard_drive(partition_number)?;
    Ok(BootEntry {
        attributes: BootEntryAttributes::LOAD_OPTION_ACTIVE,
        description: format!("Finix{ts}"),
        file_path_list: Some(FilePathList {
            file_path: FilePath {
                path: loader.to_string(),
            },
            hard_drive: hd,
        }),
        optional_data: optional
            .encode_utf16()
            .flat_map(|c| c.to_le_bytes())
            .collect(),
    })
}

pub fn make_finix_entry(ts: i64, partition_number: u32, loader: &str, optional: &str) -> BootEntry {
    try_make_finix_entry(ts, partition_number, loader, optional)
        .unwrap_or_else(|e| die(format!("make_finix_entry: {e}")))
}

pub fn try_insert_finix(mgr: &mut MemoryStore, id: u16, ts: i64) -> eros::Result<()> {
    let entry = try_make_finix_entry(ts, 1, "\\EFI\\Finix\\bootx64.efi", "")?;
    mgr.add_boot_entry(id, entry)
        .with_context(|| format!("inserting Finix entry Boot{id:04X} ts={ts}"))?;
    Ok(())
}

pub fn insert_finix(mgr: &mut MemoryStore, id: u16, ts: i64) {
    try_insert_finix(mgr, id, ts).unwrap_or_else(|e| die(format!("{e}")))
}

pub fn try_insert_finix_with_loader(
    mgr: &mut MemoryStore,
    id: u16,
    ts: i64,
    loader: &str,
    optional: &str,
) -> eros::Result<()> {
    let entry = try_make_finix_entry(ts, 1, loader, optional)?;
    mgr.add_boot_entry(id, entry)
        .with_context(|| format!("inserting Finix entry Boot{id:04X} loader={loader:?}"))?;
    Ok(())
}

pub fn insert_finix_with_loader(
    mgr: &mut MemoryStore,
    id: u16,
    ts: i64,
    loader: &str,
    optional: &str,
) {
    try_insert_finix_with_loader(mgr, id, ts, loader, optional)
        .unwrap_or_else(|e| die(format!("{e}")))
}

pub fn try_insert_non_finix(mgr: &mut MemoryStore, id: u16, desc: &str) -> eros::Result<()> {
    if desc.is_empty() {
        return Err(eros::error!("non-Finix description must not be empty"));
    }
    let entry = BootEntry {
        attributes: BootEntryAttributes::LOAD_OPTION_ACTIVE,
        description: desc.to_string(),
        file_path_list: Some(FilePathList {
            file_path: FilePath {
                path: "\\EFI\\Other\\boot.efi".to_string(),
            },
            hard_drive: try_dummy_hard_drive(1)?,
        }),
        optional_data: vec![],
    };
    mgr.add_boot_entry(id, entry)
        .with_context(|| format!("inserting non-Finix entry Boot{id:04X} desc={desc:?}"))?;
    Ok(())
}

pub fn insert_non_finix(mgr: &mut MemoryStore, id: u16, desc: &str) {
    try_insert_non_finix(mgr, id, desc).unwrap_or_else(|e| die(format!("{e}")))
}

pub fn try_boot_order(mgr: &MemoryStore) -> eros::Result<Vec<u16>> {
    Ok(mgr.get_boot_order().context("reading BootOrder")?)
}

pub fn boot_order(mgr: &MemoryStore) -> Vec<u16> {
    try_boot_order(mgr).unwrap_or_default()
}

pub fn try_set_boot_order(mgr: &mut MemoryStore, order: Vec<u16>) -> eros::Result<()> {
    let order_clone = order.clone();
    mgr.set_boot_order(order)
        .with_context(|| format!("writing BootOrder {order_clone:?}"))?;
    Ok(())
}

pub fn set_boot_order(mgr: &mut MemoryStore, order: Vec<u16>) {
    try_set_boot_order(mgr, order).unwrap_or_else(|e| die(format!("{e}")))
}

pub fn try_simulate_boot(mgr: &dyn VarManager) -> eros::Result<Option<(u16, BootEntry)>> {
    let order = match mgr.get_boot_order() {
        Ok(o) => o,
        Err(EfiError::VarNotFound { .. }) => return Ok(None),
        Err(e) => return Err(eros::error!(e).context("reading BootOrder for simulate_boot")),
    };
    for id in order {
        let var = Variable::new(&format!("Boot{id:04X}"));
        match BootEntry::read(mgr, &var) {
            Ok(entry)
                if entry
                    .attributes
                    .contains(BootEntryAttributes::LOAD_OPTION_ACTIVE) =>
            {
                return Ok(Some((id, entry)))
            }
            Ok(_) => continue,
            Err(e) => {
                eprintln!("finix-bootctl: warning: failed to parse boot entry {var:?}: {e}");
                continue;
            }
        }
    }
    Ok(None)
}

pub fn simulate_boot(mgr: &dyn VarManager) -> Option<(u16, BootEntry)> {
    try_simulate_boot(mgr).unwrap_or_else(|e| {
        eprintln!("finix-bootctl: warning: simulate_boot failed: {e}");
        None
    })
}

pub fn try_simulate_finix_boot(mgr: &dyn VarManager) -> eros::Result<Option<(u16, i64)>> {
    Ok(try_list_generations(mgr)?
        .into_iter()
        .next()
        .map(|g| (g.id, g.ts)))
}

pub fn simulate_finix_boot(mgr: &dyn VarManager) -> Option<(u16, i64)> {
    try_simulate_finix_boot(mgr).unwrap_or_else(|e| {
        eprintln!("finix-bootctl: warning: simulate_finix_boot failed: {e}");
        None
    })
}

#[cfg(test)]
#[path = "../tests/mod.rs"]
mod tests;
