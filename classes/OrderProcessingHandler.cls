// Apex class to handle a sequence of queueable jobs:
// 1. Send Order Confirmation Email
// 2. Generate and Attach Invoice
// 3. Notify Delivery Agent

public class OrderProcessingHandler {

    // Step 1: Send Order Confirmation Email
    public class SendOrderConfirmation implements Queueable {
        private Id orderId;

        public SendOrderConfirmation(Id ordId) {
            this.orderId = ordId;
        }

        public void execute(QueueableContext context) {
            // Fetch Order and Customer Email
            Order__c order = [SELECT Id, Customer__r.Email__c FROM Order__c WHERE Id = :orderId];

            if (order.Customer__r.Email__c != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{order.Customer__r.Email__c});
                email.setSubject('Order Confirmation');
                email.setPlainTextBody('Thank you for your order! Your order ID is: ' + order.Id);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            }

            // Chain next job: Generate Invoice
            System.enqueueJob(new GenerateInvoice(orderId));
        }
    }

    // Step 2: Generate and Attach Invoice
    public class GenerateInvoice implements Queueable {
        private Id orderId;

        public GenerateInvoice(Id ordId) {
            this.orderId = ordId;
        }

        public void execute(QueueableContext context) {
            // Create dummy invoice as ContentVersion
            ContentVersion invoice = new ContentVersion();
            invoice.Title = 'Invoice_' + orderId;
            invoice.PathOnClient = 'Invoice.pdf';
            invoice.VersionData = Blob.valueOf('This is a sample invoice for Order ID: ' + orderId);
            insert invoice;

            // Chain next job: Notify Delivery Agent
            System.enqueueJob(new NotifyDeliveryAgent(orderId));
        }
    }

    // Step 3: Notify Delivery Agent
    public class NotifyDeliveryAgent implements Queueable {
        private Id orderId;

        public NotifyDeliveryAgent(Id ordId) {
            this.orderId = ordId;
        }

        public void execute(QueueableContext context) {
            // Fetch Order and Delivery Agent Email
            Order__c order = [SELECT Id, Delivery_Agent__r.Email__c FROM Order__c WHERE Id = :orderId];

            if (order.Delivery_Agent__r.Email__c != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{order.Delivery_Agent__r.Email__c});
                email.setSubject('New Order Assigned');
                email.setPlainTextBody('A new order has been assigned to you. Order ID: ' + order.Id);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            }
        }
    }

}

 How to use it:
From an Apex Trigger, Flow, or button click, enqueue the first step like this:
System.enqueueJob(new OrderProcessingHandler.SendOrderConfirmation(orderId));
