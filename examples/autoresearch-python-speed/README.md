# Example: autoresearch on a Python function

- Target: `target.py` (the agent edits this and nothing else)
- Eval: `./eval.sh` prints `metric: <seconds>` (lower is better). It checks
  correctness first, so a wrong answer is a crash, not a fast score.
- To protect the eval from the agent, add `examples/autoresearch-python-speed/eval.sh`
  to `.claude/kloop/protected.txt`.

Try it:

```
./eval.sh                      # baseline, around a second or two
# then in Claude Code, in this repo:
#   /autoresearch  -> point it at this target and eval
```

A sieve gets you most of the way; the point is to watch the loop find it,
log the discards, and stop when the noise floor makes further gains fake.
