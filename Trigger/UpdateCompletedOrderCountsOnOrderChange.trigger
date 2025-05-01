Trigger: OrderTrigger.trigger
// Trigger to update completed order counts on Delivery Agents after order insert, update, delete, or undelete
trigger OrderTrigger on Order__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        // For insert, update, and undelete, update the completed order count
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            OrderHelper.updateCompletedOrderCounts(Trigger.new, null);
        } 
        // For delete, update the completed order count based on old orders
        else if (Trigger.isDelete) {
            OrderHelper.updateCompletedOrderCounts(null, Trigger.old);
        }
    }
}


Handler: OrderHelper.cls
public class OrderHelper {
    // Updates the count of completed orders for each Delivery Agent based on new or old orders
    public static void updateCompletedOrderCounts(List<Order__c> newList, List<Order__c> oldList) {
        Set<Id> deliveryAgentIds = new Set<Id>();

        // Collect Delivery Agent IDs from new or updated orders
        if (newList != null) {
            for (Order__c ord : newList) {
                if (ord.Delivery_Agent__c != null) {
                    deliveryAgentIds.add(ord.Delivery_Agent__c);
                }
            }
        }

        // Collect Delivery Agent IDs from deleted orders
        if (oldList != null) {
            for (Order__c ord : oldList) {
                if (ord.Delivery_Agent__c != null) {
                    deliveryAgentIds.add(ord.Delivery_Agent__c);
                }
            }
        }

        // Exit if no Delivery Agent IDs are found
        if (deliveryAgentIds.isEmpty()) return;

        // Map to store the completed order counts per Delivery Agent
        Map<Id, Integer> completedOrderCounts = new Map<Id, Integer>();
        
        // Query to count completed orders for each Delivery Agent
        for (AggregateResult ar : [
            SELECT Delivery_Agent__c, COUNT(Id) total
            FROM Order__c
            WHERE Delivery_Agent__c IN :deliveryAgentIds
            AND Status__c = 'Completed'
            GROUP BY Delivery_Agent__c
        ]) {
            completedOrderCounts.put((Id) ar.get('Delivery_Agent__c'), (Integer) ar.get('total'));
        }

        // Prepare list of Delivery Agent updates with completed order counts
        List<Delivery_Agent__c> agentsToUpdate = new List<Delivery_Agent__c>();
        for (Id agentId : deliveryAgentIds) {
            agentsToUpdate.add(new Delivery_Agent__c(
                Id = agentId,
                CompletedOrder__c = completedOrderCounts.containsKey(agentId) ? completedOrderCounts.get(agentId) : 0 // Set completed order count, default to 0 if no records
            ));
        }

        // Update Delivery Agents with the new completed order counts
        if (!agentsToUpdate.isEmpty()) {
            update agentsToUpdate;
        }
    }
}
