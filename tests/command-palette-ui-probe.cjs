const fs = require('fs');
const vm = require('vm');

const html = fs.readFileSync('ui/command-palette.html', 'utf8');
const match = html.match(/<script>([\s\S]*?)<\/script>/);
if (!match) throw new Error('inline command palette script not found');

function element() {
  const classes = new Set();
  return {
    value: '',
    checked: false,
    hidden: false,
    textContent: '',
    className: '',
    children: [],
    style: {},
    classList: {
      toggle(name, enabled) { enabled ? classes.add(name) : classes.delete(name); },
      contains(name) { return classes.has(name); },
      add(name) { classes.add(name); },
      remove(name) { classes.delete(name); },
    },
    handlers: {},
    addEventListener(type, handler) { this.handlers[type] = handler; },
    append(...items) { this.children.push(...items); },
    replaceChildren(...items) { this.children = [...items]; },
    querySelector() { return null; },
    scrollIntoView() {},
    remove() { this.removed = true; },
    focus() { this.focused = true; },
  };
}

const elementIds = [
  'query', 'results', 'empty', 'result-count', 'source-count', 'back',
  'page-bar', 'accelerator-hint', 'view', 'customize', 'actions',
  'custom-panel', 'config-error', 'actions-title', 'action-list',
  'actions-close', 'custom-close', 'reload', 'custom-query', 'set-view',
  'set-chords', 'set-delay', 'set-pinned', 'set-suggested', 'set-groups',
  'custom-title', 'custom-list',
];
const elements = new Map(elementIds.map(id => [id, element()]));
const body = element();
const messages = [];
const context = vm.createContext({
  console,
  messages,
  postToAHK(message) { messages.push(message); },
  document: {
    handlers: {},
    body,
    querySelector(selector) { return elements.get(selector.replace(/^#/, '')); },
    createElement() { return element(); },
    addEventListener(type, handler) { this.handlers[type] = handler; },
  },
  window: {
    innerWidth: 800,
    innerHeight: 560,
    chrome: { webview: { addEventListener() {} } },
  },
});

vm.runInContext(match[1], context, { filename: 'ui/command-palette.html' });
vm.runInContext(`
  const assert = (condition, label) => { if (!condition) throw new Error(label); };
  const sample = [
    { id: 'Apps:1', kind: 'action', parentId: '', depth: 1, label: 'Direct', source: 'Apps', breadcrumb: '', shortcut: 'Win+A D', detail: '' },
    { id: 'Apps:2', kind: 'group', parentId: '', depth: 1, label: 'Group', source: 'Apps', breadcrumb: '', shortcut: 'Win+A G', detail: '' },
    { id: 'Apps:3', kind: 'action', parentId: 'Apps:2', depth: 2, label: 'Nested', source: 'Apps', breadcrumb: 'Group', shortcut: 'Win+A G N', detail: '' },
    { id: 'Apps:4', kind: 'group', parentId: 'Apps:2', depth: 2, label: 'Deep group', source: 'Apps', breadcrumb: 'Group', shortcut: 'Win+A G D', detail: '' },
    { id: 'Apps:5', kind: 'action', parentId: 'Apps:4', depth: 3, label: 'Deep action', source: 'Apps', breadcrumb: 'Group › Deep group', shortcut: 'Win+A G D A', detail: '' },
    { id: 'Web:6', kind: 'action', parentId: '', depth: 1, label: 'YouTube', alias: 'video', source: 'Web', breadcrumb: '', shortcut: 'Win+W V', detail: '' },
  ];

  assert(fold('Árbol Ñandú') === 'arbol nandu', 'accent folding');
  const exact = scoreCommand('youtube', sample[5]);
  const prefix = scoreCommand('you', sample[5]);
  const subsequence = scoreCommand('yt', sample[5]);
  assert(exact > prefix && prefix > subsequence && subsequence > 0, 'fuzzy ranking order');
  assert(acceleratorForIndex(0) === '1', 'first accelerator label');
  assert(acceleratorForIndex(8) === '9', 'ninth accelerator label');
  assert(acceleratorForIndex(9) === '0', 'tenth accelerator label');
  assert(acceleratorForIndex(10) === '', 'items after ten are not numbered');

  const many = Array.from({ length: 11 }, (_, index) => ({
    id: 'Test:' + (index + 1),
    kind: 'action',
    parentId: '',
    depth: 1,
    label: 'Action ' + (index + 1),
    source: 'Test',
    breadcrumb: '',
    shortcut: '',
    detail: '',
  }));
  setPaletteState({ catalog: many, levelsPerPage: 0 });
  document.querySelector('#query').handlers.keydown({ key: '0', preventDefault() {} });
  assert(messages.at(-1).action === 'execute' && messages.at(-1).id === 'Test:10', 'zero activates tenth result');


  setPaletteState({ catalog: sample, levelsPerPage: 0 });
  assert(filtered.length === 4 && filtered.every(command => command.kind === 'action'), 'depth 0 preserves flat actions');

  setPaletteState({ catalog: sample, levelsPerPage: 1, groupsFirst: false });
  assert(filtered.map(command => command.id).join(',') === 'Apps:1,Web:6,Apps:2', 'actions-first ordering');
  setPaletteState({ catalog: sample, frecency: { 'Web:6': 4, 'Apps:2': 9 }, levelsPerPage: 1, groupsFirst: false });
  assert(filtered.map(command => command.id).join(',') === 'Web:6,Apps:1,Apps:2', 'frecency orders within kind blocks');
  const personalized = sample.map(command => ({ ...command }));
  Object.assign(personalized[5], { pinned: true, pinOrder: 1 });
  setPaletteState({
    catalog: personalized,
    frecency: { 'Apps:3': 5, 'Web:6': 4 },
    levelsPerPage: 1,
    groupsFirst: false,
    maxPinned: 1,
    maxSuggested: 1,
  });
  assert(filtered.map(command => command.id).join(',') === 'Web:6,Apps:3,Apps:1,Apps:2', 'pinned and suggested precede exploration');
  assert(sections.get(0) === 'Pinned' && sections.get(1) === 'Suggested' && sections.get(2) === 'Explore', 'home sections');
  document.querySelector('#query').value = 'group';
  filterCommands('group');
  assert(filtered[0].id === 'Apps:2' && filtered[0].kind === 'group', 'matching menu precedes matching actions');
  activate(filtered[0]);
  assert(currentGroupId === 'Apps:2' && document.querySelector('#query').value === '', 'matching menu opens its page and clears search');
  assert(goBack() && currentGroupId === null, 'searched menu returns to root');
  filterCommands('video');
  assert(filtered.length === 1 && filtered[0].id === 'Web:6', 'alias search');
  openActions(filtered[0]);
  actionEntries[0].run();
  assert(messages.at(-1).action === 'togglePin' && messages.at(-1).id === 'Web:6', 'action panel pin toggle');
  closeActions();
  setPaletteState({ catalog: sample, customizationCatalog: [{ id: 'Apps:1', kind: 'action', source: 'Apps', label: 'Direct', alias: '', parentId: '', order: 1 }], levelsPerPage: 1, source: 'Apps', menuPreferences: { viewMode: 'groups', chordMode: true } });
  const customRow = document.querySelector('#custom-list').children[0];
  const deleteButton = customRow.children.at(-1);
  deleteButton.handlers.click({ clientX: 100, clientY: 120 });
  assert(deleteConfirmation && !messages.some(message => message.action === 'deleteItem'), 'delete waits for local confirmation');
  document.handlers.keydown({ key: 'Escape', preventDefault() {}, stopImmediatePropagation() {} });
  assert(deleteConfirmation === null, 'Escape cancels local delete confirmation');
  deleteButton.handlers.click({ clientX: 100, clientY: 120 });
  deleteConfirmation.children.at(-1).handlers.click();
  assert(messages.at(-1).action === 'deleteItem' && messages.at(-1).id === 'Apps:1', 'cursor confirmation accepts delete');
  document.handlers.keydown({ key: 'Escape', preventDefault() {}, stopImmediatePropagation() {} });
  assert(messages.at(-1).action === 'cancel', 'Escape closes palette outside confirmation');
  openCustom();
  assert(document.querySelector('#custom-panel').classList.contains('visible'), 'customization panel opens');
  closeCustom();
  setPaletteState({ catalog: sample, levelsPerPage: 1, initialQuery: 'video' });
  assert(document.querySelector('#query').value === 'video' && filtered[0].id === 'Web:6', 'seeded query from hybrid fallback');
  filterCommands('direct');
  assert(filtered[0].id === 'Apps:1', 'fuzzy relevance outranks frecency');
  setPaletteState({ catalog: sample, levelsPerPage: 1, groupsFirst: true });
  assert(filtered.map(command => command.id).join(',') === 'Apps:2,Apps:1,Web:6', 'groups-first ordering');
  document.querySelector('#query').handlers.keydown({ key: '1', preventDefault() {} });
  assert(currentGroupId === 'Apps:2', 'one opens first visible group');
  assert(goBack() && currentGroupId === null, 'accelerator group back navigation');
  document.querySelector('#query').value = 'direct';
  filterCommands('direct');
  const beforeSearchDigit = messages.length;
  assert(!activateAccelerator('1') && messages.length === beforeSearchDigit, 'digits remain searchable while query is active');
  assert(document.querySelector('#accelerator-hint').hidden, 'accelerator hint hidden while searching');
  document.querySelector('#query').value = '';
  filterCommands('');
  assert(!document.querySelector('#accelerator-hint').hidden, 'accelerator hint shown on menu pages');
  setPaletteState({ catalog: sample, levelsPerPage: 1, groupsFirst: false });
  activate(commandById('Apps:2'));
  assert(currentGroupId === 'Apps:2', 'group entry');
  assert(filtered.map(command => command.id).join(',') === 'Apps:3,Apps:4', 'group page depth 1');
  filterCommands('deep action');
  assert(filtered.length === 1 && filtered[0].id === 'Apps:5', 'search spans nested actions globally');
  filterCommands('youtube');
  assert(filtered.length === 1 && filtered[0].id === 'Web:6', 'search ignores current submenu');
  filterCommands('');
  assert(filtered.map(command => command.id).join(',') === 'Apps:3,Apps:4', 'clearing search restores submenu');
  activate(commandById('Apps:4'));
  assert(currentGroupId === 'Apps:4', 'nested group entry');
  filterCommands('deep action');
  assert(filtered.length === 1 && filtered[0].id === 'Apps:5', 'global search works inside nested submenu');
  assert(goBack() && currentGroupId === 'Apps:2', 'nested group back navigation');
  assert(goBack() && currentGroupId === null, 'root back navigation');

  setPaletteState({ catalog: sample, levelsPerPage: 2, groupsFirst: false });
  assert(filtered.map(command => command.id).join(',') === 'Apps:1,Apps:3,Web:6,Apps:4', 'depth 2 boundary and ordering');

  document.querySelector('#query').handlers.keydown({ key: 'n', altKey: true, preventDefault() {} });
  assert(levelsPerPage === 0 && currentGroupId === null, 'Alt+N cycles 2 to 0 at root');
  assert(messages.at(-1).action === 'setLevel' && messages.at(-1).level === 0, 'Alt+N persists level change');
  document.querySelector('#query').handlers.keydown({ key: 'N', altKey: true, preventDefault() {} });
  assert(levelsPerPage === 1, 'Alt+N cycles 0 to 1');
  document.querySelector('#query').handlers.keydown({ key: 'n', altKey: true, preventDefault() {} });
  assert(levelsPerPage === 2, 'Alt+N cycles 1 to 2');

  activate(commandById('Apps:2'));
  document.querySelector('#query').value = 'stale';
  focusPalette();
  assert(currentGroupId === null && document.querySelector('#query').value === '', 'reset root and query on reopen');

  const beforeGroup = messages.length;
  activate(commandById('Apps:2'));
  assert(messages.length === beforeGroup, 'group never executes');
  activate(commandById('Apps:3'));
  assert(messages.at(-1).action === 'execute' && messages.at(-1).id === 'Apps:3', 'action execution message');

  document.querySelector('#query').handlers.keydown({ key: 'Escape', preventDefault() {} });
  assert(messages.at(-1).action === 'cancel', 'Escape cancel message');
`, context);

process.stdout.write('PASS tests/command-palette-ui-probe.cjs\n');
