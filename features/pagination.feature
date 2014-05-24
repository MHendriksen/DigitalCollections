Feature: Pagination
  As a user
  In order not to be overwhelmed with results
  I want to paginate through them
  
  
  @javascript
  Scenario: Paginate 11 search results
    Given I am logged in as "admin"
    And there are "11" entities named "Werk X" of kind "Werk/Werke"
    When I go to the expert search page
    And I select "Werk" from "query[kind_id]"
    And I fill in "query[name]" with "Werk"
    And I press "Suchen"
    And I follow "Pager_right"
    Then I should see "Suchergebnis"
