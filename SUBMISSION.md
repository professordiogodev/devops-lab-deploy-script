# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `deploy.sh`: your deployment script, committed to the repo

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Walk through your script step by step. Which part guarantees the site never serves a half-copied release, and why does swapping a symlink do that?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Paste what your script printed when it deployed the broken version v1.2.0. How did it detect the problem and what exactly did it do to recover?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. What does `set -euo pipefail` change? Give one example from your script where each of `-e`, `-u` and `pipefail` prevented a silent failure.

**Your answer:**

<!-- replace this line with your answer -->

### Q4. Why does the script write to a log and use a `trap`? What does the trap clean up and in which situations does it run?

**Your answer:**

<!-- replace this line with your answer -->

### Q5. What would you change to make this safe for two engineers running it at the same time?

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->
