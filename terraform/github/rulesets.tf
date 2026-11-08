resource "github_repository_ruleset" "main_protection" {
  name        = "main-protection"
  repository  = github_repository.homelab.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    creation                      = false
    update                        = false
    update_allows_fetch_and_merge = false
    deletion                      = true
    non_fast_forward              = true
    required_linear_history       = false
    required_signatures           = false

    pull_request {
      allowed_merge_methods             = ["squash"]
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = false
    }

    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = false

      # 15368 is the GitHub Actions app: only checks reported by Actions count.
      required_check {
        context        = "gitleaks"
        integration_id = 15368
      }
      required_check {
        context        = "pre-commit"
        integration_id = 15368
      }
      required_check {
        context        = "opentofu"
        integration_id = 15368
      }
    }
  }
}
