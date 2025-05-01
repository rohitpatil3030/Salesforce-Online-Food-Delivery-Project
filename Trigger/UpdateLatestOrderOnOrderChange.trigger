Trigger: OrderTrigger.trigger
// Trigger to handle changes to Order records and update related Delivery Agent's Latest Order field
trigger OrderTrigger on Order (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        // Handle insert, update, and undelete events
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            OrderHelper.updateLatestOrder(Trigger.new, null);
        }
        // Handle delete event
        else if (Trigger.isDelete) {
            OrderHelper.updateLatestOrder(null, Trigger.old);
        }
    }
}


Helper Class: OrderHelper.cls
public class OrderHelper {
    // Updates the Latest_Order__c field on Delivery_Agent__c based on recent Order changes
    public static void updateLatestOrder(List<Order> newOrders, List<Order> oldOrders) {
        Set<Id> agentIds = new Set<Id>();

        // Collect Delivery Agent IDs from new Order records
        if (newOrders != null) {
            for (Order ord : newOrders) {
                if (ord.Delivery_Agent__c != null) {
                    agentIds.add(ord.Delivery_Agent__c);
                }
            }
        }

        // Collect Delivery Agent IDs from old Order records (for delete scenarios)
        if (oldOrders != null) {
            for (Order ord : oldOrders) {
                if (ord.Delivery_Agent__c != null) {
                    agentIds.add(ord.Delivery_Agent__c);
                }
            }
        }

        // Exit early if no agents are affected
        if (agentIds.isEmpty()) return;

        // Map to hold the latest Order ID per Delivery Agent
        Map<Id, Id> agentToLatestOrder = new Map<Id, Id>();

        // Aggregate query to get the most recent OrderDate for each agent
        for (AggregateResult ar : [
            SELECT Delivery_Agent__c agentId, MAX(OrderDate) maxDate
            FROM Order
            WHERE Delivery_Agent__c IN :agentIds
            GROUP BY Delivery_Agent__c
        ]) {
            Date latestDate = (Date) ar.get('maxDate');
            Id agentId = (Id) ar.get('agentId');

            // Query to get the actual Order ID for the max OrderDate
            List<Order> orders = [
                SELECT Id FROM Order
                WHERE Delivery_Agent__c = :agentId AND OrderDate = :latestDate
                ORDER BY LastModifiedDate DESC LIMIT 1
            ];

            // Store the Order ID mapped to the agent
            if (!orders.isEmpty()) {
                agentToLatestOrder.put(agentId, orders[0].Id);
            }
        }

        // Prepare Delivery Agent records for update
        List<Delivery_Agent__c> agentsToUpdate = new List<Delivery_Agent__c>();
        for (Id agentId : agentToLatestOrder.keySet()) {
            agentsToUpdate.add(new Delivery_Agent__c(
                Id = agentId,
                Latest_Order__c = agentToLatestOrder.get(agentId) // Update the lookup field
            ));
        }

        // Perform DML update only if there are agents to update
        if (!agentsToUpdate.isEmpty()) {
            update agentsToUpdate;
        }
    }
}
