require File.dirname(__FILE__) + '/../test_helper'
require 'date'

class TodoTest < Test::Unit::TestCase
  fixtures :todos, :users, :contexts

  def setup
    @not_completed1 = Todo.find(1).reload
    @not_completed2 = Todo.find(2).reload
    @completed = Todo.find(8).reload
  end
  
  # Test loading a todo item
  def test_load
    assert_kind_of Todo, @not_completed1
    assert_equal 1, @not_completed1.id
    assert_equal 1, @not_completed1.context_id
    assert_equal 2, @not_completed1.project_id
    assert_equal "Call Bill Gates to find out how much he makes per day", @not_completed1.description
    assert_nil @not_completed1.notes
    assert @not_completed1.completed? == false
    assert_equal 1.week.ago.utc.strftime("%Y-%m-%d %H:%M"), @not_completed1.created_at.strftime("%Y-%m-%d %H:%M")
    assert_equal 2.week.from_now.utc.strftime("%Y-%m-%d"), @not_completed1.due.strftime("%Y-%m-%d")
    assert_nil @not_completed1.completed_at
    assert_equal 1, @not_completed1.user_id
  end
  
  def test_completed
    assert_kind_of Todo, @completed
    assert @completed.completed?
    assert_not_nil @completed.completed_at
  end
  
  # Validation tests
  #
  def test_validate_presence_of_description
    assert_equal "Call dinosaur exterminator", @not_completed2.description
    @not_completed2.description = ""
    assert !@not_completed2.save
    assert_equal 1, @not_completed2.errors.count
    assert_equal "can't be blank", @not_completed2.errors.on(:description)
  end
  
  def test_validate_length_of_description
    assert_equal "Call dinosaur exterminator", @not_completed2.description
    @not_completed2.description = generate_random_string(101)
    assert !@not_completed2.save
    assert_equal 1, @not_completed2.errors.count
    assert_equal "is too long (maximum is 100 characters)", @not_completed2.errors.on(:description)
  end
  
  def test_validate_length_of_notes
    assert_equal "Ask him if I need to hire a skip for the corpses.", @not_completed2.notes
    @not_completed2.notes = generate_random_string(60001)
    assert !@not_completed2.save
    assert_equal 1, @not_completed2.errors.count
    assert_equal "is too long (maximum is 60000 characters)", @not_completed2.errors.on(:notes)
  end
  
  def test_defer_an_existing_todo
    @not_completed2
    assert_equal :active, @not_completed2.current_state
    @not_completed2.show_from = next_week
    assert @not_completed2.save, "should have saved successfully" + @not_completed2.errors.to_xml
    assert_equal :deferred, @not_completed2.current_state
  end
  
  def test_create_a_new_deferred_todo
    user = users(:other_user)
    item = user.todos.build
    item.show_from = next_week
    item.context_id = 1
    item.description = 'foo'
    assert item.save, "should have saved successfully" + item.errors.to_xml
    assert_equal :deferred, item.current_state
  end
end
