(function () {
  function normalize(value) {
    return (value || '')
      .toLocaleLowerCase('pt-BR')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim();
  }

  function initializeTrackerPicker(picker) {
    if (!picker || picker.dataset.initialized === 'true') return;
    picker.dataset.initialized = 'true';

    var search = picker.querySelector('.issue-tag-tracker-search');
    var options = Array.prototype.slice.call(picker.querySelectorAll('.issue-tag-tracker-option'));
    var noResults = picker.querySelector('.issue-tag-tracker-no-results');

    function filterOptions() {
      var term = normalize(search.value);
      var visible = 0;

      options.forEach(function (option) {
        var matches = normalize(option.dataset.searchName).indexOf(term) !== -1;
        option.classList.toggle('issue-tag-filtered-out', !matches);
        if (matches) visible += 1;
      });

      noResults.style.display = visible === 0 ? 'block' : 'none';
    }

    search.addEventListener('input', filterOptions);
  }

  function initializeRolePicker(picker) {
    if (!picker || picker.dataset.initialized === 'true') return;
    picker.dataset.initialized = 'true';

    var search = picker.querySelector('.issue-tag-role-search');
    var options = Array.prototype.slice.call(picker.querySelectorAll('.issue-tag-role-option'));
    var noResults = picker.querySelector('.issue-tag-role-no-results');
    var settings = picker.closest('.issue-tag-roles-settings');
    var activeRoleTarget = picker.dataset.activeRoleTarget;
    var activeRoles = settings && activeRoleTarget
      ? settings.querySelector('[data-active-role-list="' + activeRoleTarget + '"]')
      : null;

    function filterOptions() {
      var term = normalize(search.value);
      var visible = 0;

      options.forEach(function (option) {
        var matches = normalize(option.dataset.searchName).indexOf(term) !== -1;
        option.classList.toggle('issue-tag-filtered-out', !matches);
        if (matches) visible += 1;
      });

      noResults.style.display = visible === 0 ? 'block' : 'none';
    }

    function updateActiveRoles() {
      if (!activeRoles) return;

      var list = activeRoles.querySelector('ul');
      var empty = activeRoles.querySelector('.nodata');
      var selectedNames = options.filter(function (option) {
        var checkbox = option.querySelector('input[type="checkbox"]');
        return checkbox && checkbox.checked;
      }).map(function (option) {
        var name = option.querySelector('span');
        return name ? name.textContent.trim() : '';
      }).filter(Boolean);

      list.textContent = '';
      selectedNames.forEach(function (name) {
        var item = document.createElement('li');
        item.textContent = name;
        list.appendChild(item);
      });
      empty.hidden = selectedNames.length > 0;
    }

    search.addEventListener('input', filterOptions);
    options.forEach(function (option) {
      var checkbox = option.querySelector('input[type="checkbox"]');
      if (checkbox) checkbox.addEventListener('change', updateActiveRoles);
    });
  }

  function initializeAll() {
    document.querySelectorAll('.issue-tag-tracker-picker').forEach(initializeTrackerPicker);
    document.querySelectorAll('.issue-tag-role-picker').forEach(initializeRolePicker);
    document.querySelectorAll('.issue-tag-collaborative').forEach(initializeCollaborativeTag);
    initializeGlobalRoleSettings();
  }

  function initializeGlobalRoleSettings() {
    var toggle = document.querySelector('[data-issue-tag-roles-toggle]');
    var settings = document.querySelector('#issue-tag-roles-settings');
    if (!toggle || !settings || toggle.dataset.initialized === 'true') return;
    toggle.dataset.initialized = 'true';

    var cancel = settings.querySelector('.issue-tag-roles-cancel');
    var search = settings.querySelector('.issue-tag-role-search');

    toggle.addEventListener('click', function (event) {
      event.preventDefault();
      settings.hidden = !settings.hidden;
      if (!settings.hidden && search) search.focus();
    });

    if (cancel) {
      cancel.addEventListener('click', function () {
        settings.hidden = true;
      });
    }
  }

  function initializeCollaborativeTag(container) {
    if (!container || container.dataset.collaborativeInitialized === 'true') return;
    container.dataset.collaborativeInitialized = 'true';

    var toggle = container.querySelector('.issue-tag-collaborative-toggle');
    var form = container.querySelector('.issue-tag-collaborative-form');
    var submit = container.querySelector('.issue-tag-collaborative-submit');
    var cancel = container.querySelector('.issue-tag-collaborative-cancel');
    var status = container.querySelector('.issue-tag-collaborative-status');
    var name = container.querySelector('#collaborative_issue_tag_name');
    var description = container.querySelector('#collaborative_issue_tag_description');
    var color = container.querySelector('#collaborative_issue_tag_color');

    function selectCreatedTag(tag) {
      var options = document.querySelector('#redmine_issue_tag_options');
      if (!options) return;

      var existing = options.querySelector('[data-issue-tag-id="' + tag.id + '"] input[type="checkbox"]');
      if (existing) {
        existing.checked = true;
        return;
      }

      var label = document.createElement('label');
      label.className = 'issue-tag-checkbox-option';
      label.dataset.issueTagId = tag.id;
      label.title = tag.description || '';

      var checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.name = 'redmine_issue_tag_ids[]';
      checkbox.id = 'redmine_issue_tag_ids_' + tag.id;
      checkbox.value = tag.id;
      checkbox.checked = true;

      var text = document.createElement('span');
      text.textContent = tag.name;

      label.appendChild(checkbox);
      label.appendChild(text);
      options.appendChild(label);
    }

    function closeForm() {
      form.hidden = true;
      status.textContent = '';
      status.className = 'issue-tag-collaborative-status';
    }

    toggle.addEventListener('click', function () {
      form.hidden = !form.hidden;
      if (!form.hidden) name.focus();
    });
    cancel.addEventListener('click', closeForm);

    submit.addEventListener('click', function () {
      var tracker = document.querySelector('#issue_tracker_id');
      var token = document.querySelector('meta[name="csrf-token"]');

      status.textContent = '';
      submit.disabled = true;

      fetch(container.dataset.createUrl, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': token ? token.content : ''
        },
        body: JSON.stringify({
          tracker_id: tracker ? tracker.value : null,
          redmine_issue_tag: {
            name: name.value,
            description: description.value,
            color: color.value
          }
        })
      }).then(function (response) {
        return response.json().then(function (body) {
          if (!response.ok) throw body;
          return body;
        });
      }).then(function (tag) {
        selectCreatedTag(tag);
        name.value = '';
        description.value = '';
        color.value = '#3b82f6';
        status.textContent = container.dataset.successMessage;
        status.className = 'issue-tag-collaborative-status success';
      }).catch(function (error) {
        var messages = error && error.errors ? error.errors : [container.dataset.errorMessage];
        status.textContent = messages.join(' ');
        status.className = 'issue-tag-collaborative-status error';
      }).finally(function () {
        submit.disabled = false;
      });
    });
  }

  document.addEventListener('DOMContentLoaded', initializeAll);
  document.addEventListener('turbo:load', initializeAll);
})();
