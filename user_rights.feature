Feature: Import user rights

Scenario: I update the user rights
    I log into instance "{%LETTUCE_DATABASE%}"
    And I open tab menu "ADMINISTRATION"
    I open accordion menu "Security"
    I click on menu "Import User Access from File" and open the window
    I click on "add attachment"
    I fill "File to import" with "file"
    I click on "Process User Rights"
    I click on "Close" and close the window
    I log out

