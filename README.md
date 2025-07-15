# VoteForge: Decentralized Governance Engine

A revolutionary on-chain governance framework that transforms traditional voting mechanisms into a sophisticated stake-weighted democracy built for the Bitcoin ecosystem.

## Overview

VoteForge enables communities to collectively shape their future through transparent, immutable decision-making processes. Participants can lock their assets to gain voting influence, propose community initiatives, and execute collective decisions automatically through a quadratic-influence model where stake translates to voting power.

## Key Features

- **Stake-weighted voting** with sybil resistance
- **Automated proposal lifecycle management**
- **Built-in quorum and consensus mechanisms**
- **Anti-manipulation safeguards**
- **Self-executing governance decisions**
- **Time-bound proposals** with configurable durations
- **Transparent vote tracking** and immutable records

## System Architecture

### Core Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Staking       │    │   Proposal      │    │   Voting        │
│   System        │    │   Management    │    │   Engine        │
│                 │    │                 │    │                 │
│ • Stake tokens  │    │ • Create        │    │ • Cast votes    │
│ • Track weight  │    │ • Validate      │    │ • Weight calc   │
│ • Anti-sybil    │    │ • Execute       │    │ • Tally results │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Governance    │
                    │   Registry      │
                    │                 │
                    │ • Proposals     │
                    │ • User stakes   │
                    │ • Vote records  │
                    └─────────────────┘
```

### Data Structures

#### Proposals Map

Stores comprehensive proposal metadata including creator, title, description, voting period, status, and vote tallies.

#### User Stakes Map

Tracks each participant's staked amount, determining their voting weight and eligibility.

#### Votes Map

Records individual votes with weight calculations, preventing double-voting and enabling transparent auditing.

## Contract Architecture

### State Management

- **Configuration Variables**: Minimum stake requirements, proposal durations, and system parameters
- **Data Maps**: Efficient storage of proposals, stakes, and votes with O(1) lookup
- **Validation Layer**: Comprehensive input validation and state consistency checks

### Access Control

- **Stake-based Authorization**: Voting power proportional to committed stake
- **Proposal Creation**: Minimum stake threshold prevents spam
- **Execution Rights**: Automated execution based on consensus rules

### Economic Model

- **Quadratic Influence**: Stake amount determines voting weight
- **Quorum Requirements**: 10% of total stake must participate
- **Sybil Resistance**: Economic cost of participation deters manipulation

## Data Flow

### Proposal Lifecycle

```
1. STAKE TOKENS
   User stakes STX → Gains voting power
   
2. CREATE PROPOSAL
   Staked user submits proposal → Validation → Active status
   
3. VOTING PERIOD
   Users cast weighted votes → Real-time tally updates
   
4. CONSENSUS CHECK
   End block reached → Quorum verification → Result determination
   
5. EXECUTION
   Success criteria met → Automated execution → Status update
```

### Vote Processing

```
Vote Submission → Validation Chain → Weight Calculation → Tally Update
                      ↓
    ┌─ Proposal active?
    ├─ User has stake?
    ├─ Already voted?
    └─ Valid vote value?
                      ↓
            Apply stake weight to vote
                      ↓
        Update proposal yes/no tallies
```

## API Reference

### Public Functions

#### `stake(amount: uint)`

Stakes STX tokens to gain voting power in governance decisions.

#### `create-proposal(title: string, description: string, duration: uint)`

Creates a new governance proposal with specified parameters and voting duration.

#### `vote(proposal-id: uint, vote-for: bool)`

Casts a weighted vote on an active proposal using staked tokens as weight.

#### `execute-proposal(proposal-id: uint)`

Executes a successful proposal that meets quorum and consensus requirements.

### Read-Only Functions

#### `get-proposal(proposal-id: uint)`

Retrieves complete proposal information and current vote tallies.

#### `get-user-stake(user: principal)`

Returns the amount of tokens staked by a specific user.

#### `get-user-vote(proposal-id: uint, user: principal)`

Gets a user's vote and weight for a specific proposal.

#### `is-executable(proposal-id: uint)`

Checks if a proposal meets execution requirements.

## Security Features

### Anti-Manipulation

- **Double-vote prevention**: Each user can vote only once per proposal
- **Stake verification**: Voting power directly tied to economic commitment
- **Time-bound proposals**: Prevents indefinite voting periods

### Validation Layer

- **Input sanitization**: Title and description length limits
- **State consistency**: Proposal status and timing validation
- **Authorization checks**: Stake requirements for participation

## Configuration

### Default Parameters

- **Minimum proposal stake**: 100,000 satoshis
- **Proposal duration**: 144 blocks (~1 day)
- **Quorum requirement**: 10% of total staked tokens

### Error Handling

Comprehensive error codes for debugging and user feedback:

- `ERR-NOT-AUTHORIZED`: Insufficient permissions
- `ERR-ALREADY-VOTED`: Duplicate vote attempt
- `ERR-PROPOSAL-EXPIRED`: Voting period ended
- `ERR-INSUFFICIENT-STAKE`: Below minimum stake threshold

## Getting Started

1. **Deploy Contract**: Deploy VoteForge to your Bitcoin Layer 2 network
2. **Stake Tokens**: Participants stake STX to gain voting power
3. **Create Proposals**: Staked users can submit governance proposals
4. **Vote**: Community votes on active proposals with stake-weighted influence
5. **Execute**: Successful proposals are automatically executed

## Use Cases

- **Protocol Upgrades**: Community-driven protocol improvements
- **Treasury Management**: Collective resource allocation decisions
- **Parameter Adjustments**: Governance of system parameters
- **Feature Proposals**: New functionality and enhancement voting
- **Community Initiatives**: Ecosystem development and growth proposals

## License

This smart contract is provided as-is for educational and development purposes. Review and audit before production deployment.
