var Login = {
    showOpenid: function() {
        $('#database_auth_form').hide();
        $('#openid_auth_form').show();
        $('#alternate_auth_openid').hide();
        $('#alternate_auth_database').show();
        $('#openid_url').focus();
        $('#openid_url').select();
        $.cookie('preferred_auth', 'openid');
    },

    showDatabase: function(container) {
        $('#openid_auth_form').hide();
        $('#database_auth_form').show();
        $('#alternate_auth_database').hide();
        $('#alternate_auth_openid').show();
        $('#user_login').focus();
        $('#user_login').select();
        $.cookie('preferred_auth', 'database');
    }
}

var TracksForm = {
    toggle: function(toggleDivId, formContainerId, formId, hideLinkText, hideLinkTitle, showLinkText, showLinkTitle) {
        $('#'+formContainerId).toggle();
        toggleDiv = $('#'+toggleDivId);
        toggleLink = toggleDiv.find('a');
        if (toggleDiv.hasClass('hide_form')) {
            toggleLink.text(showLinkText).attr('title', showLinkTitle);
        }
        else {
            toggleLink.text(hideLinkText).attr('title', hideLinkTitle);
            $('#'+formId+' input:first').focus();
        }
        toggleDiv.toggleClass('hide_form');
    }, 
    get_period: function() {
        if ($('recurring_todo_recurring_period_daily').checked) {
            return 'daily';
        } 
        else if ($('recurring_todo_recurring_period_weekly').checked) {
            return 'weekly';
        }
        else if ($('recurring_todo_recurring_period_monthly').checked) {
            return 'monthly';
        }
        else if ($('recurring_todo_recurring_period_yearly').checked) {
            return 'yearly';
        }
        else {
            return 'no period'
        }
    },
    get_edit_period: function() {
        if ($('recurring_edit_todo_recurring_period_daily').checked) {
            return 'daily';
        } 
        else if ($('recurring_edit_todo_recurring_period_weekly').checked) {
            return 'weekly';
        }
        else if ($('recurring_edit_todo_recurring_period_monthly').checked) {
            return 'monthly';
        }
        else if ($('recurring_edit_todo_recurring_period_yearly').checked) {
            return 'yearly';
        }
        else {
            return 'no period'
        }
    },
    hide_all_recurring: function () {
        $('recurring_daily').hide();
        $('recurring_weekly').hide();
        $('recurring_monthly').hide();
        $('recurring_yearly').hide();
    },
    hide_all_edit_recurring: function () {
        $('recurring_edit_daily').hide();
        $('recurring_edit_weekly').hide();
        $('recurring_edit_monthly').hide();
        $('recurring_edit_yearly').hide();
    },
    toggle_overlay: function () {
        el = document.getElementById("overlay");
        el.style.visibility = (el.style.visibility == "visible") ? "hidden" : "visible";
    }
}

var TodoBehavior = {
    enableToggleNotes: function() {
        jQuery(".show_notes").unbind('click').bind('click', function () {
            jQuery(this).next().toggle("fast"); return false;
        });
    }
}

$.fn.clearForm = function() {
  return this.each(function() {
    var type = this.type, tag = this.tagName.toLowerCase();
    if (tag == 'form')
      return $(':input',this).clearForm();
    if (type == 'text' || type == 'password' || tag == 'textarea')
      this.value = '';
    else if (type == 'checkbox' || type == 'radio')
      this.checked = false;
    else if (tag == 'select')
      this.selectedIndex = -1;
  });
};

/****************************************
 * Unobtrusive jQuery written by Eric Allen
 ****************************************/

/* Set up authenticity token proplery */
$(document).ajaxSend(function(event, request, settings) {
  if ( settings.type == 'POST' ) {
    if(typeof(AUTH_TOKEN) != 'undefined'){
      settings.data = (settings.data ? settings.data + "&" : "")
        + "authenticity_token=" + encodeURIComponent( AUTH_TOKEN ) + "&"
        + "_source_view=" + encodeURIComponent( SOURCE_VIEW );
    } else {
      settings.data = (settings.data ? settings.data + "&" : "")
        + "_source_view=" + encodeURIComponent( SOURCE_VIEW );
    }
    request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  }
  request.setRequestHeader("Accept", "text/javascript");
});

function toggle_star_remote(ev){
  ev.preventDefault();
  $.post(this.href, {_method: 'put'}, null, 'script');
}

function toggle_checkbox_remote(ev){
  params = {_method: 'put'};
  if(typeof(TAG_NAME) !== 'undefined')
    params._tag_name = TAG_NAME;
  $.post(this.value, params, null, 'script');
}

todoItems = {
  // public
  ensureVisibleWithEffectAppear: function(elemId){
    $('#'+elemId).fadeIn(400);
  },
  expandNextActionListing: function(itemsElem, skipAnimation) {
    itemsElem = $(itemsElem);
    if(skipAnimation == true) {
      itemsElem.show();
    }
    else {
      itemsElem.show('blind', 400);
    }
    todoItems.showContainer(itemsElem.parentNode);
  },
  collapseNextActionListing: function(itemsElem, skipAnimation) {
    itemsElem = $(itemsElem);
    if(skipAnimation == true) {
      itemsElem.hide();
    }
    else {
      itemsElem.hide('blind', 400);
    }
    todoItems.hideContainer(itemsElem.parentNode);
  },
  ensureContainerHeight: function(itemsElem) {
    $(itemsElem).css({height: '', overflow: ''});
  },
  expandNextActionListingByContext: function(itemsElemId, skipAnimation){
    todoItems.expandNextActionListing($('#'+itemsElemId).get(), skipAnimation);
  },

  // private
  buildCookieName: function(containerElem) {
    tracks_login = $.cookie('tracks_login');
    return 'tracks_'+tracks_login+'_context_' + containerElem.id + '_collapsed';
  },
  showContainer: function(containerElem) {
    imgSrc = $(containerElem).find('.container_toggle img').attr('src');
    $(containerElem).find('.container_toggle img').attr('src', imgSrc.replace('expand', 'collapse'));
  },
  hideContainer: function (containerElem) {
    imgSrc = $(containerElem).find('.container_toggle img').attr('src');
    $(containerElem).find('.container_toggle img').attr('src', imgSrc.replace('collapse', 'expand'));
  }
}

function setup_container_toggles(){
  // bind handlers
  $('.container_toggle').click(function(evt){
      toggle_target = $(this.parentNode.parentNode).find('.toggle_target');
      if(toggle_target.is(':visible')){
        // hide it
        imgSrc = $(this).find('img').attr('src');
        $(this).find('img').attr('src', imgSrc.replace('collapse', 'expand'));
        $.cookie(todoItems.buildCookieName(this.parentNode.parentNode), true);
      } else {
        // show it
        imgSrc = $(this).find('img').attr('src');
        $(this).find('img').attr('src', imgSrc.replace('expand', 'collapse'));
        $.cookie(todoItems.buildCookieName(this.parentNode.parentNode), null);
      }
      toggle_target.toggle('blind');
      });
  // set to cookied state
  $('.container.context').each(function(){
      if($.cookie(todoItems.buildCookieName(this))){
        imgSrc = $(this).find('.container_toggle img').attr('src');
        $(this).find('.container_toggle img').attr('src', imgSrc.replace('collapse', 'expand'));
        $(this).find('.toggle_target').hide();
        }
      });
}

function askIfNewContextProvided() {
  var givenContextName = $('#todo_context_name').val();
  if (givenContextName.length == 0) return true; // do nothing and depend on rails validation error
  for (var i = 0; i < contextNames.length; ++i) {
    if (contextNames[i] == givenContextName) return true;
  }
  return confirm('New context "' + givenContextName + '" will be also created. Are you sure?');
}

function update_order(event, ui){
        container = $(ui.item).parent();
        row = $(ui.item).children('.sortable_row');
        
        url = '';
        if(row.hasClass('context'))
            url = '/contexts/order';
        else if(row.hasClass('project'))
            url = '/projects/order';
        else {
          console.log("Bad sortable list");
          return;
        }
        $.post(url,
            container.sortable("serialize"),
            function(){row.effect('highlight', {}, 1000)},
            'script');
}

/* Unobtrusive jQuery behavior */

function project_defaults(){
  if(defaultContexts[$(this).val()] !== undefined) {
    context_name = $(this).parents('form').find('input[name=context_name]');
    if(context_name.attr('edited') === undefined){
      context_name.val(defaultContexts[$(this).val()]);
    }
  }
  if(defaultTags[$(this).val()] !== undefined) {
    tag_list = $(this).parents('form').find('input[name=tag_list]');
    if(tag_list.attr('edited') === undefined){
      tag_list.val(defaultTags[$(this).val()]);
    }
  }
}

function enable_rich_interaction(){
  $('input.Date').datepicker();
  /* Autocomplete */
  $('input[name=context_name]').autocomplete(contextNames);
  $('input[name=project[default_context_name]]').autocomplete(contextNames);
  $('input[name=project_name]').autocomplete(projectNames);
  $('input[name=tag_list]').autocomplete(tagNames, {multiple: true,multipleSeparator:','});

  /* have to bind on keypress because of limitataions of live() */
  $('input[name=project_name]').live('keypress', function(){
      $(this).bind('blur', project_defaults);
  });

  $('input[name=context_name]').live('keypress', function(){
      $(this).attr('edited', 'true');
  });
  $('input[name=tag_list]').live('keypress', function(){
      $(this).attr('edited', 'true');
  });
}

$(document).ready(function() {
  /* Nifty corners */
  Nifty("div#recurring_new_container","normal");

  /* fade flashes and alerts in automatically */
  $(".alert").fadeOut(8000);

  /* set behavior for star icon */
  $(".item-container a.star_item").
    live('click', toggle_star_remote);

  /* set behavior for toggle checkboxes */
  $(".item-container input.item-checkbox").
    live('click', toggle_checkbox_remote);

  setup_container_toggles();


  $('#toggle_action_new').click(function(){
    TracksForm.toggle('toggle_action_new', 'todo_new_action', 'todo-form-new-action',
      '« Hide form', 'Hide next action form',
      'Add a next action »', 'Add a next action');
    });

  $('.edit-form a.negative').live('click', function(){
      $(this).parents('.container').find('.item-show').show();
      $(this).parents('.container').find('.project').show();
      $(this).parents('.edit-form').hide();
      });
  
  $(".date_clear").live('click', function() {
      /* add behavior to clear the date both buttons for show_from and due */
      $(this).prev().val('');
    });

  /* recurring todo behavior */

  /* behavior for delete icon */
  $('.item-container a.delete_icon').live('click', function(evt){
      evt.preventDefault();
      params = {};
      if(typeof(TAG_NAME) !== 'undefined'){
        params._tag_name = TAG_NAME;
      }
      if(confirm("Are you sure that you want to "+this.title+"?")){
        itemContainer = $(this).parents(".item-container");
        itemContainer.block({message: null});
        params._method = 'delete';
        $.post(this.href, params, function(){
          itemContainer.unblock();
          }, 'script');
      }
    });

  /* behavior for edit icon */
  $('.item-container a.edit_icon').live('click', function(evt){
      evt.preventDefault();
      params = {};
      if(typeof(TAG_NAME) !== 'undefined'){
        params._tag_name = TAG_NAME;
      }
      itemContainer = $(this).parents(".item-container");
      $(this).effect('pulsate', {times: 1}, 800);
      $.get(this.href, params, function(){
        }, 'script');
    });

  $("#recurring_todo_new_action_cancel").click(function(){
      $('#recurring-todo-form-new-action').clearForm();
      $('#recurring-todo-form-new-action input:first').focus();
      TracksForm.hide_all_recurring();
      $('#recurring_daily').show();
      TracksForm.toggle_overlay();
  });

  $("#recurring_todo_edit_action_cancel").live('click', function(){
      $('#recurring-todo-form-edit-action').clearForm();
      $('#recurring-todo-form-edit-action input:first').focus();
      TracksForm.hide_all_recurring();
      $('#recurring_daily').show();
      TracksForm.toggle_overlay();
  });
  $("#recurring_edit_period input").live('click', function(){
      $.each(['daily', 'weekly', 'monthly', 'yearly'], function(){
        $('#recurring_edit_'+this).hide();
        });
      $('#recurring_edit_'+this.id.split('_')[5]).show();
    });

  $('div.context span#context_name').editable(function(value, settings){
      context_id = $(this).parents('.container.context').get(0).id.split('c')[1];
      highlight = function(){
        $('div.context span#context_name').effect('highlight', {}, 500);
      };
      $.post('/contexts/update/'+context_id, {'context[name]': value}, highlight);
      return(value);
      }, {style: 'padding:0px', submit: "OK"});

  /* Projects behavior */
  $('h2#project_name').editable(function(value, settings){
      project_id = $(this).parents('.container').children('div').get(0).id.split('_')[2];
      highlight = function(){
        $('h2#project_name').effect('highlight', {}, 500);
      };
      $.post('/projects/update/'+project_id, {'project[name]': value, 'update_project_name': 'true'}, highlight, 'script');
      return(value);
      }, {style: 'padding:0px', submit: "OK"});

  $('.alphabetize_link').click(function(evt){
      evt.preventDefault();
      if(confirm('Are you sure that you want to sort these projects alphabetically? This will replace the existing sort order.')){
        alphaSort = $(this).parents('.alpha_sort');
        alphaSort.block({message:null});
        $.post(this.href, {}, function(){alphaSort.unblock()}, 'script');
      }
    });

  $('.actionize_link').click(function(evt){
      evt.preventDefault();
      if(confirm('Are you sure that you want to sort these projects by the number of tasks? This will replace the existing sort order.')){
        taskSort = $(this).parents('.tasks_sort');
        taskSort.block({message:null});
        $.post(this.href, {}, function(){taskSort.unblock()}, 'script');
      }
    });

  $('a.delete_project_button').live('click', function(evt){
      evt.preventDefault();
      if(confirm("Are you sure that you want to "+this.title+"?")){
        $(this).parents('.project').block({message: null});
        params = {_method: 'delete'};
        $.post(this.href, params, null, 'script');
      }
  });

  $('#toggle_project_new').click(function(evt){
      TracksForm.toggle('toggle_project_new', 'project_new', 'project-form',
        '« Hide form', 'Hide new project form',
        'Create a new project »', 'Add a project');
      });

  $(".project-list .edit-form a.negative").live('click', function(evt){
      evt.preventDefault();
      $(this).parents('.list').find('.project').show();
      $(this).parents('.edit-form').hide();
      $(this).parents('.edit-form').find('form').clearForm();
  });

  $(".add_note_link a").live('click', function(){
      $('#new-note').show();
      $('#new-note form').clearForm();
      $('#new-note form input:first').focus();
    });

  $("#list-active-projects").sortable({handle: '.handle', update: update_order});
  $("#list-hidden-projects").sortable({handle: '.handle', update: update_order});
  $("#list-completed-projects").sortable({handle: '.handle', update: update_order});

  /* Contexts behavior */
  $('#toggle_context_new').click(function(evt){
      TracksForm.toggle('toggle_context_new', 'context_new', 'context-form',
        '« Hide form', 'Hide new context form',
        'Create a new context »', 'Add a context');
  });

  $("#list-contexts-active").sortable({handle: '.handle', update: update_order});
  $("#list-contexts-hidden").sortable({handle: '.handle', update: update_order});
  /*
      <%= apply_behavior 'a.edit_context_button:click', :prevent_default => true do |page, element|
               element.up('.context').toggle 
               editform = element.up('.list').down('.edit-form')
               editform.toggle 
               editform.visual_effect(:appear) 
               editform.down('input').focus
         end
      -%>
      */
  /* Gets called from some AJAX callbacks, too */
  enable_rich_interaction();
});
