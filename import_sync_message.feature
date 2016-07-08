Feature: Import sync rules (message)

Scenario: I update the sync rules (data/message) on the sync server
    I log into instance "{%LETTUCE_DATABASE%}"
    And I open tab menu "ADMINISTRATION"
    I click on menu "Rules|Data Synchronization Rules"
    I click on "Messages Rules"
    I click "Import" in the side panel and open the window
    I fill "CSV File:" with "file"
    I click on "Import File"
    I should see "Imported * objects" in the section "3. File imported"
    I click on "Close" and close the window
    I log out

