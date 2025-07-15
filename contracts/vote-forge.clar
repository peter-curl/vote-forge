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