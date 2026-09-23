# Neovim cheatsheet

Open this file at any time with `<leader>ch` or `:Cheatsheet`. Press `q` to close it.

Leader is `Space`. Local leader is `,`.

One rule of this config is not standard: `[` moves **forward** and `]` moves
**backward**. This applies to hunks, errors, quickfix entries and buffers.

---

## 1. Git: who changed this line, and why

Put the cursor on any line, then press the key.

| Key | Action |
| --- | --- |
| `<leader>gm` | Blame the line. Shows the commit, the author, the date, the full commit message and the merge request that brought the commit in. |
| `<leader>go` | Open the merge request for this line in the browser. |
| `<leader>gC` | Open the diff of the commit that last changed this line. |
| `<leader>gf` | List every commit that touched this file. `Enter` shows that commit's diff, `Ctrl-a` opens its merge request. |
| `<leader>gb` | Short blame popup for the line (gitsigns). |
| `<leader>gB` | Turn on or off the blame text at the end of every line. |
| `<leader>gL` | Full blame pane beside the file, one commit per line. |
| `<leader>gh` | History of this file in diffview. |
| `<leader>gh` (visual) | History of the selected lines only. |
| `<leader>gH` | History of the whole branch. |

Inside the `<leader>gm` window:

| Key | Action |
| --- | --- |
| `o` | Open the merge request in the browser. |
| `O` | Open the commit page in the browser. |
| `d` | Open the commit diff in diffview. |
| `y` | Copy the commit hash. |
| `q` | Close the window. |

How the merge request is found: the line gives a commit, and the first merge
commit that contains that commit carries the line `See merge request
espressif/esp-idf!NNNNN`. The URL is built from your `gitlab` remote. If the
commit is not merged yet on this branch, the window says so.

### Git changes in the working tree

| Key | Action |
| --- | --- |
| `[h` / `]h` | Next / previous changed block (hunk). |
| `<leader>gp` | Preview the hunk under the cursor. |
| `<leader>gs` / `<leader>gr` | Stage / reset the hunk. Works on a visual selection too. |
| `<leader>gS` / `<leader>gu` | Stage the whole file / undo the last stage. |
| `<leader>gd` | Diff this file against the index. |
| `<leader>gq` | Send all hunks to the quickfix list. |
| `<leader>gv` | Side-by-side review of the working tree. Press again to close. |
| `<leader>gV` | Side-by-side review of `master...HEAD`. |
| `<leader>gc` | Close diffview. |
| `vih` / `dih` | Select / delete the hunk as a text object. |
| `:ReviewFiles [base]` | Quickfix list of every file under review. Walk it with `[q` and `]q`. |

---

## 2. Buffers: change file, close one file

A buffer is one open file. A window is one viewport. Closing a buffer and
closing a window are different actions.

| Key | Action |
| --- | --- |
| `<leader>bb` | Buffer picker, most recent first. Type to filter, `Enter` to open. |
| `[b` / `]b` | Next / previous buffer. |
| `<C-^>` | Jump to the last buffer you were in. The fastest way to switch between two files. |
| `<leader>bl` | List buffers with their numbers, for `:b 7`. |
| `:b <part of name>` | Jump by name, not by number. `:b rtc_clk` is enough. `Tab` completes. |
| `<leader>bd` | **Close the current file and keep every split open.** |
| `<leader>bD` | Same, but throw away unsaved changes. |
| `<leader>bo` | Close all other files, keep the current one. |
| `<leader>wc` | Close the window, keep the file open in the buffer list. |

Note the difference. `<leader>bd` removes the file from the buffer list and
leaves the window showing the previous file. Plain `:bd` closes the window with
it, which is the behavior you want to avoid. `<leader>wc` does the opposite: it
closes the viewport only.

### Windows and splits

| Key | Action |
| --- | --- |
| `<leader>vs` / `<leader>hs` | Vertical / horizontal split. |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | Move to the window on the left, below, above, right. |
| `=` / `-` | Make the window wider / narrower. |
| `+` / `^` | Make the window taller. |
| `<C-w>o` | Close every window except this one. |
| `<C-w>=` | Give all windows the same size. |
| `<C-w>T` | Move this window to its own tab. |

---

## 3. Find things

| Key | Action |
| --- | --- |
| `<leader>jk` | Find files by name. |
| `<leader>fg` | Search text in the project (live grep). |
| `<leader>fb` | File browser. |
| `<leader>fz` | Jump to a directory you used before (zoxide). |
| `<leader>fd` | All diagnostics. |
| `<leader>ds` / `<leader>ws` | Symbols in this file / in the workspace. |
| `<leader>fv` | Search the help. |
| `<leader>fp` | List all pickers. |
| `<leader>n` | Open the yazi file manager at the current file. |

---

## 4. Code: LSP

| Key | Action |
| --- | --- |
| `K` | Show the type and documentation under the cursor. |
| `gd` / `gD` | Go to definition / declaration. |
| `gr` | References in the quickfix list. `Tab` and `Shift-Tab` walk them. |
| `gi` / `gy` | Go to implementation / type definition. |
| `<leader>ci` / `<leader>co` | Incoming / outgoing calls. |
| `<leader>rn` | Rename the symbol everywhere. |
| `<leader>ca` | Code action. |
| `<leader>e` | Show the error under the cursor. |
| `[e` / `]e` | Next / previous error. |
| `<leader>fm` | Format the file. |
| `<leader>xx` / `<leader>xX` | Trouble panel: workspace / this buffer. |
| `<leader>xs` / `<leader>xr` | Symbol outline / references panel. |
| `<C-o>` / `<C-i>` | Jump back / forward in the jump list. Use these after `gd`. |
| `gf` | Open the file path under the cursor. Good for `#include` lines. |

---

## 5. Fast editing: the line tricks

These are the ones worth learning first. Each is two or three keys.

| Keys | Result |
| --- | --- |
| `ddp` | Swap this line with the line below. |
| `ddkP` | Swap this line with the line above. |
| `yyp` | Duplicate this line. |
| `yyP` | Duplicate this line above. |
| `xp` | Swap this character with the next one. |
| `deep`, `dwwP` | Swap two words. Simpler: put the cursor on the first word and press `dawwP`. |
| `J` | Join the line below onto this one. |
| `gJ` | Join without adding a space. |
| `cc` | Clear the line and start typing, keeping the indent. |
| `S` | Same as `cc`. |
| `C` | Change from the cursor to the end of the line. |
| `D` | Delete from the cursor to the end of the line. |
| `o` / `O` | Open a new line below / above and type. |
| `~` | Flip the case of one character. |
| `g~iw` | Flip the case of the word. |
| `guiw` / `gUiw` | Word to lower case / upper case. |
| `<leader>t` | Flip the case of the word start (this config). |
| `>>` / `<<` | Indent / unindent the line. |
| `==` | Re-indent the line. `=ap` re-indents the paragraph, `gg=G` the file. |
| `.` | Repeat the last change. The most valuable key in Vim. |
| `u` / `<C-r>` | Undo / redo. |
| `J` / `K` (visual) | Move the selected lines down / up (this config). |
| `<C-a>` / `<C-x>` | Increase / decrease the number under the cursor. |

### Operator plus motion

Every edit is an operator and a motion. Learn the two halves and you get every
combination for free.

| Operator | Meaning |
| --- | --- |
| `d` | Delete. |
| `c` | Change (delete, then insert). |
| `y` | Yank (copy). |
| `>` `<` | Indent. |
| `=` | Re-indent. |
| `gu` `gU` `g~` | Case. |
| `gc` | Comment (Comment.nvim). |

| Motion | Meaning |
| --- | --- |
| `w` `b` `e` | Next word, previous word, end of word. |
| `W` `B` `E` | Same, but a word is anything between spaces. |
| `0` `^` `$` | Start of line, first non-blank, end of line. |
| `f<c>` `t<c>` | To the next `<c>` / just before it. `;` repeats, `,` repeats backward. |
| `F<c>` `T<c>` | The same backward. |
| `%` | Jump to the matching bracket. |
| `}` `{` | Next / previous blank line. |
| `gg` `G` | Top / bottom of the file. `42G` jumps to line 42. |
| `H` `M` `L` | Top, middle, bottom of the screen. |
| `zz` `zt` `zb` | Put the current line in the middle, at the top, at the bottom. |
| `*` `#` | Search for the word under the cursor, forward / backward. |
| ```` `` ``` | Jump back to where you were before the last jump. |

So `d2w` deletes two words, `ct)` changes up to the next `)`, `y%` copies a
whole bracket block, `gcap` comments the paragraph.

### Text objects

Text objects work inside an operator. `i` means inner, `a` means around.

| Object | Meaning |
| --- | --- |
| `iw` / `aw` | Word / word with its space. |
| `is` / `as` | Sentence. |
| `ip` / `ap` | Paragraph. |
| `i(` `i{` `i[` `i<` | Inside brackets. `a(` includes the brackets. |
| `i"` `i'` `` i` `` | Inside quotes. |
| `it` / `at` | Inside an XML or HTML tag. |
| `if` / `af` | Inside a function / the whole function (treesitter). |
| `ic` / `ac` | Class. |
| `ih` | A git hunk. |

Examples: `ci"` retypes a string, `daf` deletes a whole function, `vip` selects
a paragraph, `yi{` copies a block body.

### Surrounding characters (mini.surround)

| Keys | Result |
| --- | --- |
| `sa` + motion + char | Add a surround. `saiw"` puts quotes around the word. |
| `sd` + char | Delete a surround. `sd"` removes the quotes. |
| `sr` + old + new | Replace a surround. `sr"'` turns `"x"` into `'x'`. |
| `sf` / `sF` | Find the surround right / left. |
| `sh` | Highlight the surround. |

### Jumping with flash

| Keys | Result |
| --- | --- |
| `zk` | Type two characters, then the label that appears, to jump anywhere on screen. |
| `Zk` | Jump to a treesitter node. |
| `R` (visual or operator) | Treesitter search. |

---

## 6. Search and replace

| Keys | Result |
| --- | --- |
| `/text` then `n` / `N` | Search forward, next / previous match. |
| `?text` | Search backward. |
| `*` | Search for the word under the cursor. |
| `:%s/old/new/g` | Replace in the whole file. |
| `:%s/old/new/gc` | Replace with a question before each change. |
| `:s/old/new/g` | Replace on this line only. |
| `:'<,'>s/old/new/g` | Replace inside the visual selection. |
| `:noh` | Clear the search highlight. |
| `:g/pattern/d` | Delete every line that matches. |
| `:v/pattern/d` | Delete every line that does not match. |
| `:%s/<C-r><C-w>/new/g` | `Ctrl-r Ctrl-w` inserts the word under the cursor into the command line. |

Search is case insensitive in this config, so `/Foo` also finds `foo`. Add `\C`
to force a case sensitive search.

---

## 7. Registers, macros, marks

| Keys | Result |
| --- | --- |
| `"ayy` | Yank the line into register `a`. `"ap` pastes it. |
| `"+y` | Yank to the system clipboard. Yanks already go there in this config. |
| `"0p` | Paste the last yank, even after you deleted something else. |
| `qa` ... `q` | Record a macro into register `a`. |
| `@a` | Play the macro. `@@` plays it again. |
| `10@a` | Play it ten times. |
| `:%norm @a` | Play the macro on every line of the file. |
| `ma` | Set mark `a` here. |
| `` `a `` | Jump back to mark `a`. |
| `` `. `` | Jump to the last change. |
| `<C-o>` / `<C-i>` | Walk back and forward through your jumps. |

A macro is a recorded set of keystrokes. Record the edit once on one line, then
replay it on the rest.

---

## 8. Visual mode

| Keys | Result |
| --- | --- |
| `v` / `V` / `<C-v>` | Character, line, block selection. |
| `gv` | Reselect the last selection. |
| `<C-v>` then `I` then text then `Esc` | Insert the text at the start of every selected line. |
| `<C-v>` then `$A` | Append at the end of every selected line. |
| `>` / `<` | Indent the selection. Press `gv` to keep it selected. |
| `:'<,'>!sort` | Pipe the selection through a shell command. |

---

## 9. Files and sessions

| Keys | Result |
| --- | --- |
| `:w` / `:wa` | Save this file / all files. |
| `:e!` | Reload the file from disk and lose your changes. |
| `:e <path>` | Open a file. |
| `:sp <path>` / `:vs <path>` | Open a file in a horizontal / vertical split. |
| `:tabnew` / `gt` / `gT` | New tab, next tab, previous tab. |
| `:qa!` | Quit and lose everything. |
| `<C-n>` | Pick a colorscheme. |
| `<leader>ll` | Turn on the spell checker. `[s` and `]s` move between mistakes, `z=` suggests. |

---

## 10. Suggested practice order

1. `.` and `u`. Repeat and undo make everything else cheap.
2. `ciw`, `ci"`, `ca(`. Change a thing without selecting it first.
3. `f` and `t` with `;`. Move inside a line without arrow keys.
4. `ddp`, `yyp`, `J`, `>>`.
5. `<leader>gm` on any line you do not understand. The commit message and the
   merge request explain more than the code does.
6. One macro per week until `qa @a` feels normal.
