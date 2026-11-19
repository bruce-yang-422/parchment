import assert from 'node:assert/strict';
import { parseQuery, searchDocuments, buildSnippet } from '../assets/js/search.js';

assert.deepEqual(parseQuery('  Btrfs  "cold backup" btrfs '), ['btrfs', 'cold backup']);
assert.deepEqual(parseQuery(''), []);

const record = (path, content) => ({
  key: path.join('/').toLowerCase(),
  entry: { name: path.at(-1), path },
  content,
});
const records = [
  record(['伺服器', '備份機制.md'], '# 備份\n使用 Btrfs snapshot 每 10 分鐘建立快照。\n冷備份 cold backup。'),
  record(['網路配置.md'], 'VLAN 與防火牆設定，不含快照。'),
  record(['btrfs 指令.md'], 'subvolume list'),
];

let result = searchDocuments(records, 'btrfs');
assert.equal(result.total, 2);
assert.equal(result.results[0].record.entry.name, 'btrfs 指令.md', '檔名命中排在前面');

result = searchDocuments(records, '快照 btrfs');
assert.deepEqual(result.results.map(r => r.record.entry.name), ['備份機制.md']);

result = searchDocuments(records, '伺服器');
assert.equal(result.total, 1, '路徑也可被搜尋');

result = searchDocuments(records, '"cold backup"');
assert.equal(result.total, 1);
const { text, ranges } = result.results[0].snippet;
assert.equal(text.slice(ranges[0][0], ranges[0][1]).toLowerCase(), 'cold backup');

assert.equal(searchDocuments(records, '不存在的字').total, 0);
assert.equal(searchDocuments(records, '   ').total, 0);

const long = `${'a'.repeat(200)}\n目標字在這裡${'b'.repeat(200)}`;
const snippet = buildSnippet(long, ['目標字'], long.indexOf('目標字'), 30);
assert.ok(snippet.text.startsWith('…目標字'), snippet.text);
assert.ok(snippet.text.endsWith('…'));
assert.deepEqual(snippet.ranges, [[1, 4]]);

console.log('search-test: passed');
