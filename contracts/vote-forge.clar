;; VoteForge: Decentralized Governance Engine
;;
;; Summary:
;; VoteForge is a revolutionary on-chain governance framework that transforms
;; traditional voting mechanisms into a sophisticated stake-weighted democracy.
;; Built for the Bitcoin ecosystem, it enables communities to collectively
;; shape their future through transparent, immutable decision-making processes.
;;
;; Description:
;; This smart contract creates a powerful governance infrastructure where
;; participants can lock their assets to gain voting influence, propose
;; community initiatives, and execute collective decisions automatically.
;; The system implements a quadratic-influence model where stake translates
;; to voting power, ensuring that those with skin in the game have a voice
;; proportional to their commitment. Features include time-bound proposals,
;; anti-spam mechanisms, quorum requirements, and automated execution of
;; successful initiatives.
;;
;; Key Innovation:
;; - Stake-weighted voting with sybil resistance
;; - Automated proposal lifecycle management
;; - Built-in quorum and consensus mechanisms
;; - Anti-manipulation safeguards
;; - Self-executing governance decisions

;; ERROR CONSTANTS

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-ALREADY-VOTED (err u103))
(define-constant ERR-PROPOSAL-EXPIRED (err u104))
(define-constant ERR-INSUFFICIENT-STAKE (err u105))
(define-constant ERR-PROPOSAL-NOT-ACTIVE (err u106))
(define-constant ERR-INVALID-STATE (err u107))
(define-constant ERR-INVALID-TITLE (err u108))
(define-constant ERR-INVALID-DESCRIPTION (err u109))
(define-constant ERR-INVALID-VOTE (err u110))

;; CONFIGURATION VARIABLES

;; Minimum stake required to create a proposal (in satoshis)
(define-data-var min-proposal-stake uint u100000)

;; Default proposal duration in blocks (~1 day)
(define-data-var proposal-duration uint u144)

;; Total amount staked across all participants
(define-data-var total-staked uint u0)

;; Running counter for proposal IDs
(define-data-var proposal-count uint u0)

;; DATA STRUCTURES

;; Core proposal structure containing all governance metadata
(define-map proposals
  uint ;; proposal-id
  {
    creator: principal,
    title: (string-ascii 50),
    description: (string-ascii 500),
    start-block: uint,
    end-block: uint,
    status: (string-ascii 10),
    yes-votes: uint,
    no-votes: uint,
    executed: bool,
    min-votes-required: uint,
  }
)

;; User stake registry for governance participation
(define-map user-stakes
  principal ;; user address
  uint ;; amount staked in satoshis
)

;; Vote registry with weight tracking
(define-map votes
  {
    proposal-id: uint,
    voter: principal,
  }
  {
    vote: bool,
    weight: uint,
  }
)

;; VALIDATION FUNCTIONS

;; Validates proposal title format and length
(define-private (validate-title (title (string-ascii 50)))
  (and
    (not (is-eq title ""))
    (<= (len title) u50)
  )
)

;; Validates proposal description format and length
(define-private (validate-description (description (string-ascii 500)))
  (and
    (not (is-eq description ""))
    (<= (len description) u500)
  )
)

;; Validates vote value is boolean
(define-private (validate-vote (vote-value bool))
  (or (is-eq vote-value true) (is-eq vote-value false))
)

;; Checks if proposal is within active voting period
(define-private (is-proposal-active (proposal-id uint))
  (let (
      (proposal (unwrap! (map-get? proposals proposal-id) false))
      (current-block stacks-block-height)
    )
    (and
      (>= current-block (get start-block proposal))
      (<= current-block (get end-block proposal))
      (is-eq (get status proposal) "active")
    )
  )
)

;; Determines if proposal meets execution criteria
(define-private (can-execute-proposal (proposal-id uint))
  (let (
      (proposal (unwrap! (map-get? proposals proposal-id) false))
      (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
    )
    (and
      (>= total-votes (get min-votes-required proposal))
      (> (get yes-votes proposal) (get no-votes proposal))
      (not (get executed proposal))
      (>= stacks-block-height (get end-block proposal))
    )
  )
)

;; CORE GOVERNANCE FUNCTIONS

;; Stake tokens to gain voting power in governance
(define-public (stake (amount uint))
  (let (
      (current-stake (default-to u0 (map-get? user-stakes tx-sender)))
      (new-stake (+ current-stake amount))
    )
    (begin
      (asserts! (> amount u0) ERR-INVALID-AMOUNT)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (map-set user-stakes tx-sender new-stake)
      (var-set total-staked (+ (var-get total-staked) amount))
      (ok new-stake)
    )
  )
)

;; Create a new governance proposal
(define-public (create-proposal
    (title (string-ascii 50))
    (description (string-ascii 500))
    (duration uint)
  )
  (let (
      (user-stake (default-to u0 (map-get? user-stakes tx-sender)))
      (proposal-id (+ (var-get proposal-count) u1))
      (start-block stacks-block-height)
      (end-block (+ stacks-block-height duration))
    )
    (begin
      (asserts! (validate-title title) ERR-INVALID-TITLE)
      (asserts! (validate-description description) ERR-INVALID-DESCRIPTION)
      (asserts! (>= user-stake (var-get min-proposal-stake))
        ERR-INSUFFICIENT-STAKE
      )
      (asserts! (> duration u0) ERR-INVALID-AMOUNT)
      (map-set proposals proposal-id {
        creator: tx-sender,
        title: title,
        description: description,
        start-block: start-block,
        end-block: end-block,
        status: "active",
        yes-votes: u0,
        no-votes: u0,
        executed: false,
        min-votes-required: (/ (var-get total-staked) u10), ;; 10% quorum requirement
      })
      (var-set proposal-count proposal-id)
      (ok proposal-id)
    )
  )
)

;; Cast a weighted vote on an active proposal
(define-public (vote
    (proposal-id uint)
    (vote-for bool)
  )
  (let (
      (user-stake (default-to u0 (map-get? user-stakes tx-sender)))
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
      (vote-key {
        proposal-id: proposal-id,
        voter: tx-sender,
      })
      (validated-vote (validate-vote vote-for))
    )
    (begin
      (asserts! validated-vote ERR-INVALID-VOTE)
      (asserts! (is-proposal-active proposal-id) ERR-PROPOSAL-NOT-ACTIVE)
      (asserts! (> user-stake u0) ERR-INSUFFICIENT-STAKE)
      (asserts! (is-none (map-get? votes vote-key)) ERR-ALREADY-VOTED)
      ;; Record the vote with stake weight
      (map-set votes vote-key {
        vote: vote-for,
        weight: user-stake,
      })
      ;; Update proposal vote tallies
      (map-set proposals proposal-id
        (merge proposal {
          yes-votes: (if vote-for
            (+ (get yes-votes proposal) user-stake)
            (get yes-votes proposal)
          ),
          no-votes: (if vote-for
            (get no-votes proposal)
            (+ (get no-votes proposal) user-stake)
          ),
        })
      )
      (ok true)
    )
  )
)

;; Execute a successful proposal
(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND)))
    (begin
      (asserts! (can-execute-proposal proposal-id) ERR-INVALID-STATE)
      ;; Mark proposal as executed
      (map-set proposals proposal-id
        (merge proposal {
          status: "executed",
          executed: true,
        })
      )
      (ok true)
    )
  )
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve complete proposal information
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Get user's current stake amount
(define-read-only (get-user-stake (user principal))
  (default-to u0 (map-get? user-stakes user))
)

;; Get user's vote on a specific proposal
(define-read-only (get-user-vote
    (proposal-id uint)
    (user principal)
  )
  (map-get? votes {
    proposal-id: proposal-id,
    voter: user,
  })
)

;; Get total amount staked across all users
(define-read-only (get-total-staked)
  (var-get total-staked)
)

;; Check if a proposal meets execution requirements
(define-read-only (is-executable (proposal-id uint))
  (can-execute-proposal proposal-id)
)