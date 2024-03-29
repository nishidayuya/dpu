# dpu: determine permanent URI

[![License X11](https://img.shields.io/badge/license-X11-blue.svg)](https://raw.githubusercontent.com/nishidayuya/dpu/master/LICENSE.txt)
[![Gem Version](https://badge.fury.io/rb/dpu.svg)](https://rubygems.org/gems/dpu)
[![Build Status](https://github.com/nishidayuya/dpu/workflows/ubuntu/badge.svg)](https://github.com/nishidayuya/dpu/actions?query=workflow%3Aubuntu)

`dpu` command shows us permanent source-code URI.

```console
$ dpu array.c 4133 4136
https://github.com/ruby/ruby/blob/v3_2_2/array.c#L4133-L4136
```

## Requirements

- Ruby

## Installation

```console
$ gem install dpu
```

## Usage

Get permanent source code URI:

```console
$ dpu path_to_code
```

Get permanent source code URI with line range:

```console
$ dpu path_to_code start_line_number end_line_number
```

### Emacs integration

Write following code to your `.emacs`, and evaluate it.

<details>

<summary>.emacs sample</summary>

```emacs-lisp
(define-key global-map (kbd "C-x L")
  (lambda ()
    (interactive)
    (save-window-excursion
      (let* ((start-line-number (line-number-at-pos (if (region-active-p) (region-beginning))))
             (end-line-number
              (if mark-active
                  (line-number-at-pos
                   (+ (region-end)
                      (if (= (line-beginning-position) (region-end)) -1 0)))
                ))
             (proc (apply
                    #'start-process
                    "dpu" "*Dpu Command Result*"
                    "dpu" buffer-file-name
                    (number-to-string start-line-number)
                    (if end-line-number
                        (list (number-to-string end-line-number)))
                    ))
             (kill-new-with-buffer-string
              (lambda (process signal)
                (when (memq (process-status process) '(exit signal))
                  (let* ((buf (process-buffer process)))
                    (with-current-buffer buf
                      (kill-new (s-chomp (buffer-string)))
                      (message "Copied: %s" (current-kill 0 t))
                      (kill-buffer buf)
                      )))))
             )
        (run-with-timer 10 nil (lambda (process) (kill-buffer (process-buffer process))) proc)
        (if (process-live-p proc)
            (set-process-sentinel proc kill-new-with-buffer-string))
        )
      )))
```

</details>

Then type `C-x L` to copy permanent URI. `C-y` to paste it.

---

Original asynchronous execution idea is made by [@mk2](https://github.com/mk2) ([#20](https://github.com/nishidayuya/dpu/pull/20)). Thanks! :tada:

### Textbringer integration

```ruby
define_command(:copy_permanent_uri, doc: "Copy permanent URI") do
  require "dpu"
  b = Buffer.current
  uri = Dpu.determine_permanent_uri(Pathname(b.file_name), start_line_number: b.current_line)
  KILL_RING.push(uri)
  Clipboard.copy(uri) if CLIPBOARD_AVAILABLE
  message("Copied: #{uri}")
end

GLOBAL_MAP.define_key("\C-xL", :copy_permanent_uri)
```

### Visual Studio Code integration

See [Copy permanent URL](https://marketplace.visualstudio.com/items?itemName=nishidayuya.copy-permanent-url) extension on Visual Studio Marketplace.

### Other editor integration

Write pull-request or issue, please!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nishidayuya/dpu .
