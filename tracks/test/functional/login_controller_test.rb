require File.dirname(__FILE__) + '/../test_helper'
require 'login_controller'
require_dependency "login_system"

# Re-raise errors caught by the controller.
class LoginController; def rescue_action(e) raise e end; end

class LoginControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    assert_equal "test", ENV['RAILS_ENV']
    assert_equal "change-me", SALT
    @controller = LoginController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  # ============================================
  # Login and logout
  # ============================================
    
  def test_invalid_login
    post :login, {:user_login => 'cracker', :user_password => 'secret', :user_noexpiry => 'on'}
    assert_response :success

    assert_session_has_no :user
    assert_template "login"
  end

  def test_login_with_valid_admin_user
    @request.session['return-to'] = "/bogus/location"
    user = login('admin', 'abracadabra', 'on')
    assert_equal user, @response.session['user']
    assert_equal user.login, "admin"
    assert_equal user.is_admin, true
    assert_equal "Login successful: session will not expire.", flash['notice']
    assert_redirect_url "http://#{@request.host}/bogus/location"
  end


  def test_login_with_valid_standard_user
    user = login('jane','sesame', 'off')
    assert_equal user, @response.session['user']
    assert_equal user.login, "jane"
    assert_equal user.is_admin, false    
    assert_equal "Login successful: session will expire after 1 hour of inactivity.", flash['notice']
    assert_redirected_to :controller => 'todo', :action => 'list'
  end

  def test_logout
    user = login('admin','abracadabra', 'on')
    get :logout
    assert_nil(session['user'])
    assert_redirected_to :controller => 'login', :action => 'login'
  end

  # Test login with a bad password for existing user
  # 
  def test_login_bad_password
    post :login, {:user_login => 'jane', :user_password => 'wrong', :user_noexpiry => 'on'}
    assert_session_has_no :user
    assert_equal "Login unsuccessful", flash['warning']
    assert_success
  end
  
  def test_login_bad_login
    post :login, {:user_login => 'blah', :user_password => 'sesame', :user_noexpiry => 'on'}
    assert_session_has_no :user
    assert_equal "Login unsuccessful", flash['warning']
    assert_success
  end
    
  # ============================================
  # Signup and creation of new users
  # ============================================
  
  # Test signup of a new user by admin
  # Check that newly created user can log in
  #
  def test_create
    admin = login('admin', 'abracadabra', 'on')
    assert_equal admin.is_admin, true
    assert_equal admin, @response.session['user']
    newbie = create('newbie', 'newbiepass')
    assert_equal "Signup successful for user newbie.", flash['notice']
    assert_redirected_to :controller => 'todo', :action => 'list'
    assert_valid newbie
    get :logout # logout the admin user
    assert_equal newbie.login, "newbie"
    assert_equal newbie.is_admin, false
    assert_not_nil newbie.preferences # have user preferences been created?
    user = login('newbie', 'newbiepass', 'on') # log in the new user
    assert_redirected_to :controller => 'todo', :action => 'list'
    assert_equal 'newbie', user.login
    assert_equal user.is_admin, false
    num_users = User.find(:all)
    assert_equal num_users.length, 3
  end
  
  # Test whether signup of new users is denied to a non-admin user
  # 
  def test_create_by_non_admin
    non_admin = login('jane', 'sesame', 'on')
    assert_equal non_admin.is_admin, false
    assert_equal non_admin, @response.session['user']
    post :signup, :user => {:login => 'newbie2', :password => 'newbiepass2', :password_confirmation => 'newbiepass2'}
    assert_template 'login/nosignup'

    num_users = User.find(:all)
    assert_equal num_users.length, 2
  end
  
  # ============================================
  # Test validations
  # ============================================
  
  def test_create_with_invalid_password
    admin = login('admin', 'abracadabra', 'on')
    assert_equal admin.is_admin, true
    assert_equal admin, @response.session['user']
    post :create, :user => {:login => 'newbie', :password => '', :password_confirmation => ''}
    num_users = User.find(:all)
    assert_equal num_users.length, 2
    assert_redirected_to :controller => 'login', :action => 'signup'    
  end
  
  def test_create_with_invalid_user
    admin = login('admin', 'abracadabra', 'on')
    assert_equal admin.is_admin, true
    assert_equal admin, @response.session['user']
    post :create, :user => {:login => 'n', :password => 'newbiepass', :password_confirmation => 'newbiepass'}
    num_users = User.find(:all)
    assert_equal num_users.length, 2
    assert_redirected_to :controller => 'login', :action => 'signup'    
  end
  
  # Test uniqueness of login
  #
  def test_validate_uniqueness_of_login
    admin = login('admin', 'abracadabra', 'on')
    assert_equal admin.is_admin, true
    assert_equal admin, @response.session['user']
    post :create, :user => {:login => 'jane', :password => 'newbiepass', :password_confirmation => 'newbiepass'}
    num_users = User.find(:all)
    assert_equal num_users.length, 2
    assert_redirected_to :controller => 'login', :action => 'signup'
  end
  
end
