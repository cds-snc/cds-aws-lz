# AFT upgrade: 1.17.1 to 1.22.0

The AFT module in this folder moves from 1.17.1 to 1.22.0 in five steps, one PR
each, in stack #494. Each step lands on the last patch release of a minor
version. Merge and apply one step, test it, then move to the next.

| Step | PR   | AFT              | Main change for us                                   |
|------|------|------------------|------------------------------------------------------|
| 1    | #493 | 1.17.1 to 1.18.1 | AWS provider 5.100.0 to 6.67.0                        |
| 2    | #497 | 1.18.1 to 1.19.0 | Account request processing                           |
| 3    | #498 | 1.19.0 to 1.20.1 | Build scripts for customizations, S3 encryption      |
| 4    | #499 | 1.20.1 to 1.21.1 | Log bucket limited to the organization, layer fix    |
| 5    | #500 | 1.21.1 to 1.22.0 | Plan-only customization runs (off), bug fixes        |

Release notes: <https://github.com/aws-ia/terraform-aws-control_tower_account_factory/releases>

## What this upgrade does not change

These were checked against every step, in the four repos AFT runs:
`aft-account-request`, `aft-account-provisioning-customizations`,
`aft-global-customizations` and `aft-account-customizations`.

- **Jinja templates.** AFT passes the same 13 template variables to every build
  script in all six versions. Our `aft-providers.jinja` and `backend.jinja` files
  use only variables from that set.
- **API helper scripts.** Every `pre-api-helpers.sh` and `post-api-helpers.sh` is
  AFT's default template and only prints a line. The 1.20.0 change to how these
  scripts' variables carry across build phases has nothing to act on.
- **Provider versions in our repos.** None of the four repos has a lock file, and
  their AWS provider constraints are open (`>= 3.15` or none), so their pipeline
  runs already use the newest AWS provider, whatever AFT version is deployed.
  The global and account customization builds on 2026-10-19 and the
  account-request build on 2026-10-21 all installed `hashicorp/aws v6.69.1`
  with Terraform 1.7.2.
- **Customization pipelines do not start on their own.** In each account's
  `<account id>-customizations-pipeline`, both sources have
  `DetectChanges = false`. Merging to `aft-global-customizations` or
  `aft-account-customizations` does not start anything, and neither does
  applying an AFT step. Customizations run only for new accounts or when the
  `aft-invoke-customizations` state machine is started.
- **AFT variables.** No variable we set is removed in any step. New variables
  have defaults that keep current behaviour.

One thing the upgrade does change outside this repo's state: from step 1, the
template AFT uses for each account's customization pipeline requires AWS
provider `>= 6.0.0`. AFT applies that template (in the `aft-create-pipeline`
CodeBuild project) when the provisioning framework runs for an account, for
example after a change to its account request. The first run after step 1
moves that account's pipeline state to provider 6. Step 1's test covers this
for one account.

## How to run each step

1. Wait until no apply is running. A plan that starts during an apply fails
   with `Error acquiring the state lock`; re-run it once the apply is done.
2. Re-run the step's plan if the step below it was applied after the plan ran.
   Until then the plan also shows the changes of the steps below.
3. Review the plan against the step's list below, then get an approval.
4. Merge with `gh stack merge <PR> --squash`. This merges only that PR and
   rebases the PRs above it.
5. Watch the "Terraform Apply" workflow, then run the common checks and the
   step's own test.

## Common checks after every apply

Use the read-only profile for the AFT management account (137554749751):

```sh
export AWS_PROFILE=aft-management-awsreadonlyaccess AWS_REGION=ca-central-1
```

**A. The apply matches the plan.** In the `org_account/aft` job of the apply
run, the `Apply complete!` counts match the plan.

**B. The account request pipelines still start on a push to `main`.**

```sh
for p in ct-aft-account-request ct-aft-account-provisioning-customizations; do
  aws codepipeline get-pipeline --name $p --query 'pipeline.triggers'
done
```

Each shows a `CodeStarSourceConnection` trigger with `push` on `main`.

**C. Every AFT Lambda runs on the new layer.**

```sh
aws lambda list-functions \
  --query 'Functions[?starts_with(FunctionName, `aft-`)].[FunctionName, Runtime, join(`,`, Layers[].Arn || `[]`)]' \
  --output text
```

All functions except `aft-lambda-layer-codebuild-trigger` show
`aft-common-<version>:1` for the new version. Steps 1 to 3 still have the
layer bug that 1.21.0 fixes, where an upgrade can leave the layer out of sync
with the function code, so this check matters most for those steps.

**D. A test account request goes through.** Change only
`change_management_parameters` of a scratch account in
`aft-account-request/terraform/scratch.tf` and merge it, as in
cds-snc/aft-account-request#329. AFT treats this as a customization request
and does not re-provision the account. Then check:

- `ct-aft-account-request` runs for the merge commit and succeeds. The push
  event can arrive late; on 2026-10-21 it took 14 minutes.
- `aft-account-request-action-trigger` logs `Customization request received`.
- The `aft-account-provisioning-framework` run for the account ends in
  `SUCCEEDED`.
- No AFT Lambda logs `ImportModuleError`, `ImportError`, a traceback or an
  `ERROR` line after the merge:

```sh
start=$(( $(date -u -v-1H +%s) * 1000 ))
for g in $(aws logs describe-log-groups --log-group-name-prefix /aws/lambda/aft- \
             --query 'logGroups[].logGroupName' --output text); do
  aws logs filter-log-events --log-group-name $g --start-time $start \
    --filter-pattern '?ImportModuleError ?ImportError ?Traceback ?"\"log_level\": \"ERROR\""' \
    --query 'events[].message' --output text
done
```

**E. A customizations run for one account** (steps 3 and 5). Start the
`aft-invoke-customizations` state machine with this input, using a scratch
account:

```json
{ "include": [ { "type": "accounts", "target_value": ["493890668711"] } ] }
```

Then check that `<account id>-customizations-pipeline` succeeds, including
the global and account customization stages.

## Step 1: 1.17.1 to 1.18.1 (#493)

**Changes:** the AWS provider moves from 5.100.0 to 6.67.0. 1.18.x makes few
other changes (Azure DevOps support, which we don't use, and dependency
updates). The lock file drops `hashicorp/tls`, which 1.18.1 does not use.

**In the plan, expect:** the Lambda layer replaced (`aft-common-1-17-1` to
`aft-common-1-18-1`) and Lambdas updated to use it. Check that nothing is
replaced or destroyed apart from the layer, since provider 6 changed some
resource schemas.

**Test:** checks A, B, C and D. Check D also runs `aft-create-pipeline` for
the scratch account under provider 6. Confirm the
`aft-account-provisioning-framework` run passes the
`aft_account_provisioning_framework_create_pipeline` state.

**Rollback:** the apply writes Terraform state in provider 6 format, which
provider 5 cannot read. Rolling back means restoring the previous version of
the `org_account/aft` state file from the versioned state bucket and
reverting the PR.

## Step 2: 1.18.1 to 1.19.0 (#497)

**Changes, all in account request processing:**

- AFT stops calling `ScanProvisionedProducts` on every request and drops its
  own concurrency limit.
- SSM values are cached within each Lambda run.
- Custom-field SSM parameters are no longer deleted and re-created on every
  provisioning run.
- The concurrency setting for customizations is applied to every batch.
- OIDC for HCP Terraform is added but stays off (`terraform_oidc_integration`
  defaults to false).
- `hashicorp/tls` (4.4.2) returns to the lock file for the OIDC code.

**Test:** checks A, B, C and D. For check D, also confirm the scratch
account's custom-field parameter (`account_alias`) still exists after the
run and was not re-created. It is under `/aft/account-request/custom-fields/`
in the account's SSM Parameter Store.

## Step 3: 1.19.0 to 1.20.1 (#498)

**Changes:**

- The minimum Terraform version is 1.6.1; we use 1.15.5 in CI and 1.7.2 in
  the AFT pipelines.
- The DynamoDB backup schedule becomes a setting; the default stays hourly.
- S3 Bucket Keys are turned on for AFT buckets, which keep their KMS keys.
- Access-log buckets use the AFT KMS key.
- The fix for Lambda archives rebuilding on every apply.
- Default VPC deletion skips regions it cannot reach instead of failing.
- With `aft_feature_cloudtrail_data_events = false`, AFT deletes the
  `aws-aft-CustomizationsCloudTrail` trail. Nothing happens for us: that trail
  has been gone since June 2025.
- Variables set in the API helper scripts now carry across build phases. Ours
  set none.

**Test:** checks A, B, C, D and E. Check E matters here because this step
changes the build scripts the customization pipelines run. After the apply,
re-run step 4's plan: it should no longer show Lambda code changes for code
that did not change.

## Step 4: 1.20.1 to 1.21.1 (#499)

**Changes:**

- The AFT log key and the AFT logging bucket in Log Archive
  (`aws-aft-logs-274536870005-ca-central-1`) accept log writes from VPC Flow
  Logs, log delivery and CloudTrail only for accounts in our organization.
- The fix for the Lambda layer getting out of sync with the function code.
- AFT caches each account's Enterprise Support enrollment.
- AFT reads the account `State` field from AWS Organizations.
- Re-running customizations when an account moves OU is opt-in
  (`aft_customization_triggers`), and we leave it off.
- 1.21.1 itself changes only the README.

**Test:** checks A, B, C and D. Before the apply, note the newest objects in
the AFT logging bucket. If anything still writes there, confirm it keeps
writing after the apply.

## Step 5: 1.21.1 to 1.22.0 (#500)

**Changes:**

- Plan-only customization runs.
- Optional export of plans to a new encrypted plan-output bucket, off by
  default.
- A customizations audit table and Lambda.
- The fix for Lambda archives missing between plan and apply.
- The fix for backend bucket replication on new deployments.

**Test:** checks A, B, C and D, then check E twice. First add
`"plan_only": true` to the input; the pipeline should run `terraform plan`
only. Then run it without the flag.

## Provider versions in the lock file

The AWS provider is 6.67.0 in all five steps, the same as the other modules.
From step 2, `hashicorp/tls` is 4.4.2. It was released on 2026-10-21 as a
security update to its Go toolchain, and AFT only uses it for the HCP
Terraform OIDC feature, which is off. Each lock file has hashes for linux and
darwin on amd64 and arm64, generated with `terraform providers lock`.
