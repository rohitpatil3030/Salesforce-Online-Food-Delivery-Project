// Trigger to handle actions after an Account record is inserted
trigger AccountTrigger on Account (after insert) {
    // Check if the operation is after insert, then call helper method to send welcome emails
    if (Trigger.isAfter && Trigger.isInsert) {
        AccountHelper.sendWelcomeEmails(Trigger.new);
    }
}

public class AccountHelper {
    // Helper method to send welcome emails to newly created accounts
    public static void sendWelcomeEmails(List<Account> newAccounts) {
        // List to hold email messages to be sent
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        // Loop through each new account record
        for (Account acc : newAccounts) {
            // Proceed only if the custom email field is populated
            if (acc.Email__c != null) {
                // Create a new email message
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { acc.Email__c }); // Set recipient
                mail.setSubject('Welcome to Our Platform, ' + acc.Name + '!'); // Set subject
                mail.setPlainTextBody(
                    'Hi ' + acc.Name + ',\n\n' +
                    'Thank you for creating an account with us. We’re excited to have you on board!' +
                    '\n\nBest regards,\nCustomer Success Team'
                ); // Set email body
                mail.setSaveAsActivity(true); // Log email as activity on the record
                emailsToSend.add(mail); // Add to email list
            }
        }

        // Send all collected emails if there are any
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
}
