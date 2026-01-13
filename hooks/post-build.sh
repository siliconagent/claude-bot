---
description: Post-build hook - verify build artifacts
---

# Post-Build Hook

Runs after the build phase completes.

## Actions

1. Verify build artifacts were created
2. Check build output directory
3. Update state with build results
4. Trigger validation phase if build succeeded
