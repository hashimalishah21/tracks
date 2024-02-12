class RecurringTodosController < ApplicationController

  helper :todos, :recurring_todos

  append_before_filter :init, :only => [:index, :new, :edit]
  append_before_filter :get_recurring_todo_from_param, :only => [:destroy, :toggle_check, :toggle_star, :edit, :update]

  def index
    @recurring_todos = current_user.recurring_todos.find(:all, :conditions => ["state = ?", "active"])
    @completed_recurring_todos = current_user.recurring_todos.find(:all, :conditions => ["state = ?", "completed"])
    @no_recurring_todos = @recurring_todos.size == 0
    @no_completed_recurring_todos = @completed_recurring_todos.size == 0
    @count = @recurring_todos.size 
  end

  def new
  end
  
  def show
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @recurring_todo.tag_with(params[:tag_list], current_user) if params[:tag_list]
    @original_item_context_id = @recurring_todo.context_id
    @original_item_project_id = @recurring_todo.project_id

    # we needed to rename the recurring_period selector in the edit form because
    # the form for a new recurring todo and the edit form are on the same page.
    # Same goes for start_from and end_date
    params['recurring_todo']['recurring_period']=params['recurring_edit_todo']['recurring_period']
    params['recurring_todo']['end_date']=params['recurring_todo_edit_end_date']
    params['recurring_todo']['start_from']=params['recurring_todo_edit_start_from']
    
    # update project
    if params['recurring_todo']['project_id'].blank? && !params['project_name'].nil?
      if params['project_name'] == 'None'
        project = Project.null_object
      else
        project = current_user.projects.find_by_name(params['project_name'].strip)
        unless project
          project = current_user.projects.build
          project.name = params['project_name'].strip
          project.save
          @new_project_created = true
        end
      end
      params["recurring_todo"]["project_id"] = project.id
    end
    
    # update context
    if params['recurring_todo']['context_id'].blank? && !params['context_name'].blank?
      context = current_user.contexts.find_by_name(params['context_name'].strip)
      unless context
        context = current_user.contexts.build
        context.name = params['context_name'].strip
        context.save
        @new_context_created = true
      end
      params["recurring_todo"]["context_id"] = context.id
    end
    
    params["recurring_todo"]["weekly_return_monday"]=' ' if params["recurring_todo"]["weekly_return_monday"].nil?
    params["recurring_todo"]["weekly_return_tuesday"]=' ' if params["recurring_todo"]["weekly_return_tuesday"].nil?
    params["recurring_todo"]["weekly_return_wednesday"]=' ' if params["recurring_todo"]["weekly_return_wednesday"].nil?
    params["recurring_todo"]["weekly_return_thursday"]=' ' if params["recurring_todo"]["weekly_return_thursday"].nil?
    params["recurring_todo"]["weekly_return_friday"]=' ' if params["recurring_todo"]["weekly_return_friday"].nil?
    params["recurring_todo"]["weekly_return_saturday"]=' ' if params["recurring_todo"]["weekly_return_saturday"].nil?
    params["recurring_todo"]["weekly_return_sunday"]=' ' if params["recurring_todo"]["weekly_return_sunday"].nil?
    
    @saved = @recurring_todo.update_attributes params["recurring_todo"]

    respond_to do |format|
      format.js
    end
  end
  
  def create
    p = RecurringTodoCreateParamsHelper.new(params)
    @recurring_todo = current_user.recurring_todos.build(p.attributes)

    if p.project_specified_by_name?
      project = current_user.projects.find_or_create_by_name(p.project_name)
      @new_project_created = project.new_record_before_save?
      @recurring_todo.project_id = project.id
    end
    
    if p.context_specified_by_name?
      context = current_user.contexts.find_or_create_by_name(p.context_name)
      @new_context_created = context.new_record_before_save?
      @recurring_todo.context_id = context.id
    end

    @recurring_saved = @recurring_todo.save
    unless (@recurring_saved == false) || p.tag_list.blank?
      @recurring_todo.tag_with(p.tag_list, current_user)
      @recurring_todo.tags.reload
    end

    if @recurring_saved
      @message = "The recurring todo was saved"
      @todo_saved = create_todo_from_recurring_todo(@recurring_todo).nil? == false
      if @todo_saved
        @message += " / created a new todo"
      else
        @message += " / did not create todo"
      end
      @count = current_user.recurring_todos.count(:all, :conditions => ["state = ?", "active"])
    else
      @message = "Error saving recurring todo"
    end    
    
    respond_to do |format|
      format.js 
    end
  end
  
  def destroy
    
    # remove all references to this recurring todo
    @todos = current_user.todos.find(:all, {:conditions => ["recurring_todo_id = ?", params[:id]]})
    @number_of_todos = @todos.size
    @todos.each do |t|
      t.recurring_todo_id = nil
      t.save
    end
    
    # delete the recurring todo
    @saved = @recurring_todo.destroy
    @remaining = current_user.recurring_todos.count(:all)
    
    respond_to do |format|
      
      format.html do
        if @saved
          notify :notice, "Successfully deleted recurring action", 2.0
          redirect_to :action => 'index'
        else
          notify :error, "Failed to delete the recurring action", 2.0
          redirect_to :action => 'index'
        end
      end
      
      format.js do
        render
      end    
    end
  end

  def toggle_check
    @saved = @recurring_todo.toggle_completion!

    @count = current_user.recurring_todos.count(:all, :conditions => ["state = ?", "active"])
    @remaining = @count

    if @recurring_todo.active?
      @remaining = current_user.recurring_todos.count(:all, :conditions => ["state = ?", 'completed']) 
      
      # from completed back to active -> check if there is an active todo
      @active_todos = current_user.todos.count(:all, {:conditions => ["state = ? AND recurring_todo_id = ?", 'active',params[:id]]})
      # create todo if there is no active todo belonging to the activated
      # recurring_todo
      @new_recurring_todo = create_todo_from_recurring_todo(@recurring_todo) if @active_todos == 0
    end
    
    respond_to do |format|
      format.js 
    end
  end
  
  def toggle_star
    @recurring_todo.toggle_star!
    @saved = @recurring_todo.save!
    respond_to do |format|
      format.js
    end
  end
  
  class RecurringTodoCreateParamsHelper

    def initialize(params)
      @params = params['request'] || params
      attr = params['request'] && params['request']['recurring_todo']  || params['recurring_todo']
      
      # make sure all selectors (recurring_period, recurrence_selector,
      # daily_selector, monthly_selector and yearly_selector) are first in hash
      # so that they are processed first by the model
      @attributes = {
        'recurring_period' => attr['recurring_period'],
        'daily_selector' => attr['daily_selector'],
        'monthly_selector' => attr['monthly_selector'],
        'yearly_selector' => attr['yearly_selector']
      }.merge(attr)
    end
      
    def attributes
      @attributes
    end
            
    def project_name
      @params['project_name'].strip unless @params['project_name'].nil?
    end
      
    def context_name
      @params['context_name'].strip unless @params['context_name'].nil?
    end
      
    def tag_list
      @params['tag_list']
    end
            
    def project_specified_by_name?
      return false unless @attributes['project_id'].blank?
      return false if project_name.blank?
      return false if project_name == 'None'
      true
    end
      
    def context_specified_by_name?
      return false unless @attributes['context_id'].blank?
      return false if context_name.blank?
      true
    end
      
  end

  private
  
  def init 
    @days_of_week = [ ['Sunday',0], ['Monday',1], ['Tuesday', 2], ['Wednesday',3], ['Thursday',4], ['Friday',5], ['Saturday',6]]
    @months_of_year = [ 
      ['January',1], ['Februari',2], ['March', 3], ['April',4], ['May',5], ['June',6], 
      ['July',7], ['August',8], ['September',9], ['October', 10], ['November', 11], ['December',12]]
    @xth_day = [['first',1],['second',2],['third',3],['fourth',4],['last',5]]    
    @projects = current_user.projects.find(:all, :include => [:default_context])
    @contexts = current_user.contexts.find(:all)
    @default_project_context_name_map = build_default_project_context_name_map(@projects).to_json
  end
  
  def get_recurring_todo_from_param
    @recurring_todo = current_user.recurring_todos.find(params[:id])
  end
  
end
