module MedicalRecord::MedicalRecords {
    use aptos_framework::signer;
    use std::string::String;
    use aptos_framework::timestamp;
    
    /// Struct to store medical record data
    struct MedicalRecord has store, key {
        patient_address: address,
        data: String,        // Encrypted medical data
        timestamp: u64,      // Last updated timestamp
        authorized_doctors: vector<address>  // List of authorized doctors
    }

    /// Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_RECORD_EXISTS: u64 = 2;
    const E_NO_RECORD: u64 = 3;

    /// Function to create/update a medical record
    /// Only the patient can create their record
    public fun create_or_update_record(
        patient: &signer,
        data: String,
    ) acquires MedicalRecord {
        let patient_addr = signer::address_of(patient);
        
        if (!exists<MedicalRecord>(patient_addr)) {
            let record = MedicalRecord {
                patient_address: patient_addr,
                data,
                timestamp: timestamp::now_microseconds(),
                authorized_doctors: vector::empty(),
            };
            move_to(patient, record);
        } else {
            let record = borrow_global_mut<MedicalRecord>(patient_addr);
            record.data = data;
            record.timestamp = timestamp::now_microseconds();
        };
    }

    /// Function to authorize/unauthorize a doctor to access the record
    public fun manage_doctor_access(
        patient: &signer,
        doctor_address: address,
        authorize: bool
    ) acquires MedicalRecord {
        let patient_addr = signer::address_of(patient);
        assert!(exists<MedicalRecord>(patient_addr), E_NO_RECORD);
        
        let record = borrow_global_mut<MedicalRecord>(patient_addr);
        if (authorize) {
            vector::push_back(&mut record.authorized_doctors, doctor_address);
        } else {
            let (found, index) = vector::index_of(&record.authorized_doctors, &doctor_address);
            if (found) {
                vector::remove(&mut record.authorized_doctors, index);
            };
        };
    }
}
