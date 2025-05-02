//Effective data cleanup is essential to maintain system performance and ensure a clutter-free database. In my project, I implemented scheduled Apex jobs to:
//Automatically delete inactive leads that haven’t been modified in the last 365 days
//Remove unused menu items that haven’t been ordered in the past 6 months
//Clear out orders stuck in a ‘Pending’ status for an extended period

global class DataCleanupScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        
        // 1. Delete inactive Leads (not modified in last 365 days)
        List<Lead> oldLeads = [SELECT Id FROM Lead WHERE LastModifiedDate < LAST_N_DAYS:365];
        if (!oldLeads.isEmpty()) {
            delete oldLeads; // Delete leads safely
        }

        // 2. Remove unused Menu Items (not ordered in last 6 months)
        // Assuming you have a custom object Menu_Item__c and a relationship with Order__c
        Set<Id> recentlyOrderedMenuItems = new Set<Id>();
        for (Order__c ord : [SELECT Menu_Item__c FROM Order__c WHERE CreatedDate = LAST_N_MONTHS:6 AND Menu_Item__c != NULL]) {
            recentlyOrderedMenuItems.add(ord.Menu_Item__c);
        }

        List<Menu_Item__c> allMenuItems = [SELECT Id FROM Menu_Item__c];
        List<Menu_Item__c> unusedMenuItems = new List<Menu_Item__c>();

        for (Menu_Item__c item : allMenuItems) {
            if (!recentlyOrderedMenuItems.contains(item.Id)) {
                unusedMenuItems.add(item);
            }
        }

        if (!unusedMenuItems.isEmpty()) {
            delete unusedMenuItems; // Remove items not ordered in last 6 months
        }

        // 3. Clear 'Pending' orders stuck for too long (e.g., older than 15 days)
        List<Order__c> stuckOrders = [SELECT Id FROM Order__c WHERE Status__c = 'Pending' AND CreatedDate < LAST_N_DAYS:15];
        if (!stuckOrders.isEmpty()) {
            delete stuckOrders; // Clean up old pending orders
        }
    }
}

//How to Schedule This:
//You can schedule it using the Developer Console or Anonymous Apex:
DataCleanupScheduler cleanup = new DataCleanupScheduler();
String cronExp = '0 0 0 * * ?'; // Every day at midnight
System.schedule('Daily Data Cleanup Job', cronExp, cleanup);

