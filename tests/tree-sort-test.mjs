import assert from 'node:assert/strict';
import { sortTreeEntries, collectTreeFiles, treePathKey, isTimeSort } from '../assets/js/treeSort.js';

const file = (...path) => ({ type: 'file', name: path.at(-1), path });
const dir = (name, children) => ({ type: 'dir', name, path: [name], children });

const tree = [
  file('b.md'),
  dir('Zeta', [file('Zeta', 'z2.md'), file('Zeta', 'z10.md')]),
  file('A.md'),
  dir('alpha', []),
  file('c.txt'),
];
const names = list => list.map(entry => entry.name);

assert.deepEqual(names(sortTreeEntries(tree, 'name-asc')), ['alpha', 'Zeta', 'A.md', 'b.md', 'c.txt']);
assert.deepEqual(names(sortTreeEntries(tree, 'name-desc')), ['Zeta', 'alpha', 'c.txt', 'b.md', 'A.md']);
assert.deepEqual(names(sortTreeEntries(tree, 'name-asc')[1].children), ['z2.md', 'z10.md'], '數字自然排序');

const mtimes = new Map([
  [treePathKey(['b.md']), 300],
  [treePathKey(['A.md']), 100],
  [treePathKey(['c.txt']), 200],
  [treePathKey(['Zeta', 'z2.md']), 50],
  [treePathKey(['Zeta', 'z10.md']), 500],
]);
assert.deepEqual(names(sortTreeEntries(tree, 'mtime-desc', mtimes)), ['alpha', 'Zeta', 'b.md', 'c.txt', 'A.md']);
assert.deepEqual(names(sortTreeEntries(tree, 'mtime-asc', mtimes)), ['alpha', 'Zeta', 'A.md', 'c.txt', 'b.md']);
assert.deepEqual(names(sortTreeEntries(tree, 'mtime-desc', mtimes)[1].children), ['z10.md', 'z2.md']);

// 未知模式回到預設；不修改原陣列
assert.deepEqual(names(sortTreeEntries(tree, 'nope')), ['alpha', 'Zeta', 'A.md', 'b.md', 'c.txt']);
assert.equal(tree[0].name, 'b.md');

assert.equal(collectTreeFiles(tree).length, 5);
assert.ok(isTimeSort('mtime-asc'));
assert.ok(!isTimeSort('name-asc'));

console.log('tree-sort-test: passed');
