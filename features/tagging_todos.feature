Feature: Tagging todos
  In order to organise my todos in various lists
  As a Tracks user
  I want to to be able to add or edit one or more tags to todos

  Background:
    Given the following user record
      | login    | password | is_admin |
      | testuser | secret   | false    |
    And I have logged in as "testuser" with password "secret"
    And I have a context called "@pc"
    And I have a project called "hacking tracks"

  @selenium
  Scenario: I can remove a tag from a todo from the tag view and the todo will be removed
    Given I have a todo "fix tests" in context "@pc" with tags "now"
    When I go to the tag page for "now"
    Then I should see "fix tests"
    When I edit the tags of "fix tests" to "later"
    Then I should not see "fix tests"

  @selenium
  Scenario: I can add a new todo from tag view with that tag and it will be added to the page
    When I go to the tag page for "tracks"
    And I submit a new action with description "prepare release" and the tags "tracks, release" in the context "@pc"
    Then I should see "prepare release" in the context container for "@pc"

  @selenium
  Scenario: I can add a new todo from tag view with a different tag and it will not be added to the page
    When I go to the tag page for "tracks"
    And I submit a new action with description "prepare release" with tags "release, next" in the context "@pc"
    Then I should not see "prepare release"

  @selenium
  Scenario: I can move a tagged todo in tag view to a hidden project and it will move the todo on the page to the hidden container
    Given I have a hidden project called "secret"
    When I go to the tag page for "tracks"
    And I submit a new action with description "prepare release" to project "hacking tracks" with tags "release, tracks" in the context "@pc"
    Then I should see "prepare release" in the context container for "@pc"
    When I edit the project of "prepare release" to "secret"
    Then I should not see "prepare release" in the context container for "@pc"
    And I should see "prepare release" in the hidden container

  @selenium @wip
  Scenario: I can move a tagged todo in tag view to a hidden context and it will move the todo on the page to the hidden container
    Given I have a hidden context called "@secret"
    When I go to the tag page for "tracks"
    And I submit a new action with description "prepare release" and the tags "release, tracks" in the context "@pc"
    Then I should see "prepare release" in the context container for "@pc"
    When I edit the context of "prepare release" to "@secret"
    Then I should not see "prepare release" in the context container for "@pc"
    Then I should see "prepare release" in the hidden container