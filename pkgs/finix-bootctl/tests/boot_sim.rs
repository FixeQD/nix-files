use crate::cmd_delete;
use crate::testtoolkit::cmd_create_with_hard_drive;
use crate::testtoolkit::{
    boot_order, dummy_hard_drive, insert_finix, insert_non_finix, make_finix_entry, set_boot_order,
    simulate_boot, simulate_finix_boot,
};
use efivar::boot::{BootEntry, BootEntryAttributes};
use efivar::store::MemoryStore;

#[test]
fn simulate_boot_picks_first_active() {
    let mut store = MemoryStore::new();
    insert_finix(&mut store, 0, 100);
    insert_finix(&mut store, 1, 200);
    set_boot_order(&mut store, vec![1, 0]);
    let picked = simulate_boot(&store).unwrap();
    assert_eq!(picked.0, 1);
    assert_eq!(picked.1.description, "Finix200");
}

#[test]
fn simulate_boot_skips_inactive() {
    let mut store = MemoryStore::new();
    let mut entry_inactive = make_finix_entry(100, 1, "\\EFI\\boot.efi", "");
    entry_inactive.attributes = BootEntryAttributes::empty(); // not active
    use efivar::boot::BootVarWriter;
    store.add_boot_entry(0, entry_inactive).unwrap();
    insert_finix(&mut store, 1, 200);
    set_boot_order(&mut store, vec![0, 1]);
    let picked = simulate_boot(&store).unwrap();
    assert_eq!(picked.0, 1);
}

#[test]
fn simulate_boot_returns_none_if_no_active() {
    let mut store = MemoryStore::new();
    let mut entry = make_finix_entry(100, 1, "\\EFI\\boot.efi", "");
    entry.attributes = BootEntryAttributes::empty();
    use efivar::boot::BootVarWriter;
    store.add_boot_entry(0, entry).unwrap();
    set_boot_order(&mut store, vec![0]);
    assert!(simulate_boot(&store).is_none());
}

#[test]
fn simulate_boot_skips_corrupt_entry() {
    let mut store = MemoryStore::new();
    insert_finix(&mut store, 1, 200);
    use efivar::efi::{Variable, VariableFlags};
    use efivar::VarWriter;
    store
        .write(
            &Variable::new("Boot0000"),
            VariableFlags::NON_VOLATILE,
            &[0xFF],
        )
        .unwrap();
    set_boot_order(&mut store, vec![0, 1]);
    let picked = simulate_boot(&store).unwrap();
    assert_eq!(picked.0, 1);
}

#[test]
fn simulate_boot_skips_missing_variable() {
    let mut store = MemoryStore::new();
    insert_finix(&mut store, 1, 200);
    set_boot_order(&mut store, vec![0, 1]); // 0 missing
    let picked = simulate_boot(&store).unwrap();
    assert_eq!(picked.0, 1);
}

#[test]
fn simulate_finix_boot_picks_newest_generation() {
    let mut store = MemoryStore::new();
    insert_finix(&mut store, 0, 100);
    insert_finix(&mut store, 1, 300);
    insert_finix(&mut store, 2, 200);
    // BootOrder may be unsorted, but finix_boot should use list_generations sorting
    set_boot_order(&mut store, vec![0, 1, 2]);
    let picked = simulate_finix_boot(&store).unwrap();
    assert_eq!(picked, (1, 300));
}

#[test]
fn simulate_finix_boot_none_if_no_finix() {
    let mut store = MemoryStore::new();
    insert_non_finix(&mut store, 0, "Windows");
    set_boot_order(&mut store, vec![0]);
    assert!(simulate_finix_boot(&store).is_none());
}

#[test]
fn boot_simulation_after_create_and_delete_sequence() {
    let mut store = MemoryStore::new();
    let hd = dummy_hard_drive(1);
    // Simulate typical Finix lifecycle: create 3 generations, boot newest, rollback by deleting newest
    let _id0 =
        cmd_create_with_hard_drive(&mut store, hd.clone(), "\\EFI\\Finix\\boot.efi", "", 100);
    let id1 = cmd_create_with_hard_drive(&mut store, hd.clone(), "\\EFI\\Finix\\boot.efi", "", 200);
    let id2 = cmd_create_with_hard_drive(&mut store, hd.clone(), "\\EFI\\Finix\\boot.efi", "", 300);
    // Boot should pick newest
    assert_eq!(simulate_finix_boot(&store).unwrap().0, id2);
    assert_eq!(simulate_boot(&store).unwrap().0, id2);
    // Simulate failed boot -> delete newest and fallback
    cmd_delete(&mut store, id2);
    assert_eq!(simulate_finix_boot(&store).unwrap().0, id1);
    assert_eq!(simulate_boot(&store).unwrap().0, id1);
    // Delete again
    cmd_delete(&mut store, id1);
    assert_eq!(simulate_finix_boot(&store).unwrap().1, 100);
}

#[test]
fn boot_simulation_with_mixed_finix_and_non_finix() {
    let mut store = MemoryStore::new();
    insert_non_finix(&mut store, 10, "Windows");
    set_boot_order(&mut store, vec![10]);
    let hd = dummy_hard_drive(1);
    cmd_create_with_hard_drive(&mut store, hd.clone(), "\\EFI\\Finix\\boot.efi", "", 500);
    // BootOrder: Finix first, then Windows
    let order = boot_order(&store);
    assert_eq!(order[0], 0);
    assert_eq!(order[1], 10);
    // Firmware picks Finix first
    assert_eq!(simulate_boot(&store).unwrap().0, 0);
    // If Finix entry is inactive, firmware falls back to Windows
    let mut entry = BootEntry::read(&store, &efivar::efi::Variable::new("Boot0000")).unwrap();
    entry.attributes = BootEntryAttributes::empty();
    use efivar::boot::BootVarWriter;
    store.add_boot_entry(0, entry).unwrap();
    assert_eq!(simulate_boot(&store).unwrap().0, 10);
    assert_eq!(simulate_boot(&store).unwrap().1.description, "Windows");
}

#[test]
fn simulate_boot_with_empty_boot_order_returns_none() {
    let mut store = MemoryStore::new();
    insert_finix(&mut store, 0, 100);
    set_boot_order(&mut store, vec![]);
    assert!(simulate_boot(&store).is_none());
    assert!(simulate_finix_boot(&store).is_some()); // finix boot uses list_generations not BootOrder, so still some
}

#[test]
fn delete_then_simulate_boot_fallback_to_non_finix() {
    let mut store = MemoryStore::new();
    insert_non_finix(&mut store, 10, "Windows");
    set_boot_order(&mut store, vec![10]);
    let hd = dummy_hard_drive(1);
    let finix_id = cmd_create_with_hard_drive(&mut store, hd, "\\EFI\\Finix\\boot.efi", "", 100);
    assert_eq!(simulate_boot(&store).unwrap().0, finix_id);
    cmd_delete(&mut store, finix_id);
    assert_eq!(simulate_boot(&store).unwrap().0, 10);
    assert_eq!(simulate_boot(&store).unwrap().1.description, "Windows");
}

#[test]
fn full_lifecycle_with_boot_checks() {
    // Full lifecycle: start empty, create 3, delete middle, create another, verify BootOrder invariants
    let mut store = MemoryStore::new();
    let hd = dummy_hard_drive(1);
    let id_a =
        cmd_create_with_hard_drive(&mut store, hd.clone(), "\\EFI\\Finix\\boot.efi", "a", 1000);
    let id_b =
        cmd_create_with_hard_drive(&mut store, hd.clone(), "\\EFI\\Finix\\boot.efi", "b", 2000);
    let id_c =
        cmd_create_with_hard_drive(&mut store, hd.clone(), "\\EFI\\Finix\\boot.efi", "c", 3000);
    // initial order 3000,2000,1000
    assert_eq!(boot_order(&store), vec![id_c, id_b, id_a]);
    // delete middle
    cmd_delete(&mut store, id_b);
    assert_eq!(boot_order(&store), vec![id_c, id_a]);
    assert_eq!(crate::testtoolkit::list_generations(&store).len(), 2);
    // create new generation 2500 -> should be between c and a
    let id_d =
        cmd_create_with_hard_drive(&mut store, hd.clone(), "\\EFI\\Finix\\boot.efi", "d", 2500);
    assert_eq!(boot_order(&store), vec![id_c, id_d, id_a]);
    // verify all entries readable and finix_timestamp matches
    for g in crate::testtoolkit::list_generations(&store) {
        let var = efivar::efi::Variable::new(&format!("Boot{:04X}", g.id));
        let entry = BootEntry::read(&store, &var).unwrap();
        assert_eq!(
            crate::testtoolkit::finix_timestamp(&entry.description),
            Some(g.ts)
        );
    }
    // simulate boot picks newest
    assert_eq!(simulate_finix_boot(&store).unwrap().0, id_c);
    // delete newest, fallback
    cmd_delete(&mut store, id_c);
    assert_eq!(simulate_finix_boot(&store).unwrap().0, id_d);
}

#[test]
fn nvram_boot_sim_with_inactive_and_hidden() {
    let mut store = MemoryStore::new();
    // Hidden but active finix should still boot
    let mut entry = make_finix_entry(100, 1, "\\EFI\\Finix\\boot.efi", "");
    entry.attributes =
        BootEntryAttributes::LOAD_OPTION_ACTIVE | BootEntryAttributes::LOAD_OPTION_HIDDEN;
    use efivar::boot::BootVarWriter;
    store.add_boot_entry(0, entry).unwrap();
    set_boot_order(&mut store, vec![0]);
    assert!(simulate_boot(&store).is_some());
    assert_eq!(simulate_boot(&store).unwrap().0, 0);
    // Inactive hidden -> not bootable
    let mut entry2 = make_finix_entry(200, 1, "\\EFI\\boot.efi", "");
    entry2.attributes = BootEntryAttributes::LOAD_OPTION_HIDDEN; // not active
    store.add_boot_entry(1, entry2).unwrap();
    set_boot_order(&mut store, vec![1, 0]);
    assert_eq!(simulate_boot(&store).unwrap().0, 0); // skips 1
}
