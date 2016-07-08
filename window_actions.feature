Feature: Import record rules

Scenario: I update record rules
    I log into instance "{%LETTUCE_DATABASE%}"
    And I open tab menu "ADMINISTRATION"
    I open accordion menu "Customization"
    I click on menu "Low Level Objects|Actions|Window Actions"
    I click "Import" in the side panel and open the window
    I fill "CSV File:" with "file"
    I click on "Import File"
    I should see "Imported * objects" in the section "3. File imported"
    I click on "Close" and close the window
    I log out

