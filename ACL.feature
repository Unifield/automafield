Feature: Import ACL

Scenario: I update the ACL
    I log into instance "{%LETTUCE_DATABASE%}"
    And I open tab menu "ADMINISTRATION"
    I open accordion menu "Security"
    I click on menu "Access Controls List"
    I click "Import" in the side panel and open the window
    I fill "CSV File:" with "file"
    I click on "Import File"
    I should see "Imported * objects" in the section "3. File imported"
    I click on "Close" and close the window
    I log out

