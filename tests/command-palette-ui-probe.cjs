const fs = require('fs');
const vm = require('vm');

const html = fs.readFileSync('ui/command-palette.html', 'utf8');
const match = html.match(/<script>([\s\S]*?)<\/script>/);
if (!match) throw new Error('inline command palette script not found');

function element() {
  const classes = new Set();
  return {
    value: '',
    textContent: '',
    style: {},
    classList: {
      toggle(name, enabled) { enabled ? classes.add(name) : classes.delete(name); },
      contains(name) { return classes.has(name); },
    },
    handlers: {},
    addEventListener(type, handler) { this.handlers[type] = handler; },
    append() {},
    replaceChildren() {},
    querySelector() { return null; },
    scrollIntoView() {},
    focus() { this.focused = true; },
  };
}

const elements = new Map([
  ['query', element()],
  ['results', element()],
  ['empty', element()],
  ['result-count', element()],
  ['source-count', element()],
  ['back-button', element()],
  ['page-bar', element()],
]);
const messages = [];
const context = vm.createContext({
  console,
  messages,
  postToAHK(message) { messages.push(message); },
  document: {
    querySelector(selector) { return elements.get(selector.replace(/^#/, '')); },
    createElement() { return element(); },
  },
  window: {
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
    { id: 'Web:6', kind: 'action', parentId: '', depth: 1, label: 'YouTube', source: 'Web', breadcrumb: '', shortcut: 'Win+W V', detail: '' },
  ];

  assert(fold('Árbol Ñandú') === 'arbol nandu', 'accent folding');
  const exact = scoreCommand('youtube', sample[5]);
  const prefix = scoreCommand('you', sample[5]);
  const subsequence = scoreCommand('yt', sample[5]);
  assert(exact > prefix && prefix > subsequence && subsequence > 0, 'fuzzy ranking order');

  setPaletteState({ catalog: sample, levelsPerPage: 0 });
  assert(filtered.length === 4 && filtered.every(command => command.kind === 'action'), 'depth 0 preserves flat actions');

  setPaletteState({ catalog: sample, levelsPerPage: 1, groupsFirst: false });
  assert(filtered.map(command => command.id).join(',') === 'Apps:1,Web:6,Apps:2', 'actions-first ordering');
  setPaletteState({ catalog: sample, frecency: { 'Web:6': 4, 'Apps:2': 9 }, levelsPerPage: 1, groupsFirst: false });
  assert(filtered.map(command => command.id).join(',') === 'Web:6,Apps:1,Apps:2', 'frecency orders within kind blocks');
  filterCommands('direct');
  assert(filtered[0].id === 'Apps:1', 'fuzzy relevance outranks frecency');
  setPaletteState({ catalog: sample, levelsPerPage: 1, groupsFirst: true });
  assert(filtered.map(command => command.id).join(',') === 'Apps:2,Apps:1,Web:6', 'groups-first ordering');
  setPaletteState({ catalog: sample, levelsPerPage: 1, groupsFirst: false });
  activate(commandById('Apps:2'));
  assert(currentGroupId === 'Apps:2', 'group entry');
  assert(filtered.map(command => command.id).join(',') === 'Apps:3,Apps:4', 'group page depth 1');
  filterCommands('deep action');
  assert(filtered.length === 0, 'search respects visible level');
  filterCommands('deep');
  assert(filtered.length === 1 && filtered[0].id === 'Apps:4', 'search finds visible group');
  activate(filtered[0]);
  filterCommands('deep action');
  assert(filtered.length === 1 && filtered[0].id === 'Apps:5', 'nested action requires opening submenu');
  assert(goBack() && currentGroupId === 'Apps:2', 'nested group back navigation');
  assert(goBack() && currentGroupId === null, 'root back navigation');

  setPaletteState({ catalog: sample, levelsPerPage: 2, groupsFirst: false });
  assert(filtered.map(command => command.id).join(',') === 'Apps:1,Apps:3,Web:6,Apps:4', 'depth 2 boundary and ordering');

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
