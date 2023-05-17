# dpu: determine permanent URI

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

```emacs-lisp
(define-key global-map (kbd "C-x L")
  (lambda ()
    (interactive)
    (message
     (concat
      "Copied: "
      (kill-new
       (s-chomp
        (shell-command-to-string
         (concat
          "dpu "
          buffer-file-name
          " "
          (number-to-string (line-number-at-pos (region-beginning)))
          (if mark-active (concat " " (number-to-string (line-number-at-pos (region-end)))))
          )
         )))))))
```

Then type `C-x L` to copy permanent URI. `C-y` to paste it.

### Textbringer integration

```ruby
define_command(:copy_permanent_uri, doc: "Copy permanent URI") do
  require "dpu"
  b = Buffer.current
  uri = Dpu.determine_permanent_uri(Pathname(b.file_name), b.current_line, nil)
  KILL_RING.push(uri)
  Clipboard.copy(uri) if CLIPBOARD_AVAILABLE
  message("Copied: #{uri}")
end

GLOBAL_MAP.define_key("\C-xL", :copy_permanent_uri)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nishidayuya/dpu .
