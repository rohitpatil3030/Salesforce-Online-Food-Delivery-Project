trigger PreventDuplicateCustomerPhone on Customer__c (before insert, before update) {
    Set<String> phoneNumbers = new Set<String>();

    for (Customer__c cust : Trigger.new) {
        if (cust.Phone__c != null) {
            phoneNumbers.add(cust.Phone__c.trim());
        }
    }

    if (!phoneNumbers.isEmpty()) {
        // Query existing customers with same phone
        Map<String, Customer__c> existingPhonesMap = new Map<String, Customer__c>();
        for (Customer__c existing : [
            SELECT Id, Phone__c
            FROM Customer__c
            WHERE Phone__c IN :phoneNumbers
        ]) {
            existingPhonesMap.put(existing.Phone__c.trim(), existing);
        }

        for (Customer__c cust : Trigger.new) {
            if (cust.Phone__c != null) {
                String phone = cust.Phone__c.trim();
                Customer__c existing = existingPhonesMap.get(phone);
                
                if (existing != null && (Trigger.isInsert || existing.Id != cust.Id)) {
                    cust.Phone__c.addError('Duplicate Customer detected with same phone number.');
                }
            }
        }
    }
}
