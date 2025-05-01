// Trigger to prevent deletion of active Delivery Agents
trigger CustomerTrigger on Delivery_Agent__c (before delete) {
    for (Delivery_Agent__c agent : Trigger.old) {
        // Check if the agent's status is 'Active'
        if (agent.Status__c == 'Active') {
            // Prevent deletion by adding an error message
            agent.addError('You cannot delete an active delivery agent.');
        }
    }
}
