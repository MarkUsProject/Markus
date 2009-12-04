Feature: Login
  In order to allow non-anonymous usage of MarkUs features
  a User
  wants to login
  
  Scenario: Login as an instructor
    Given I am on the home page
    And I fill in "Login" with "olm_admin"
    And I fill in "Password" with "a"
    When I press "Log in"
    Then I should see "Dashboard"
    And I should see "Assignments"
    And I should see "Users"
    And I should see "Logged in as some admin (olm_admin)"
      
  Scenario: Login as a TA
    Given I am on the home page
    And I fill in "Login" with "ta1"
    And I fill in "Password" with "a"
    When I press "Log in"
    Then I should see "Home"
    And I should see "Grade Assignments"
    And I should see "Logged in as Ursula Zandt (ta1)"

  Scenario: Login as a student
    Given I am on the home page
    And I fill in "Login" with "student6"
    And I fill in "Password" with "a"
    When I press "Log in"
    Then I should see "Home"
    And I should see "Your Assignments"
    And I should see "Logged in as Audrey Devisscher (student6)"
