# 🏆 StakePot - No-Loss Saving Protocol

> **Built for Chromion Hackathon** 🚀

StakePot is an innovative no-loss saving protocol that combines the power of staking rewards with the excitement of daily raffles. Users can save their AVAX while earning staking rewards, and participate in daily raffles where one lucky winner takes home the accumulated rewards!

## 🎯 Project Overview

StakePot addresses the challenge of making saving more engaging and rewarding. Instead of traditional low-yield savings accounts, users can:

- **Save AVAX** in a secure vault
- **Earn staking rewards** through Benqi's sAVAX
- **Participate in daily raffles** with a chance to win accumulated rewards
- **Never lose their principal** - it's a true no-loss protocol

## 🔗 Chainlink Integration

This project leverages **Chainlink VRF (Verifiable Random Function)** and **Chainlink Automation** to create a fair and automated raffle system:

### Chainlink VRF
- **Fair Winner Selection**: Uses Chainlink VRF to ensure truly random and verifiable winner selection
- **Tamper-Proof**: No one can manipulate the raffle results
- **Decentralized**: Randomness is provided by a decentralized network of nodes

<img width="1300" alt="image" src="https://github.com/user-attachments/assets/29126ea0-8eea-46ee-ba9b-c5ad807c5559" />


### Chainlink Automation
- **Daily Raffle Automation**: Automatically starts raffles every 24 hours
- **Winner Selection Automation**: Automatically picks winners when conditions are met
- **Gas-Efficient**: Only executes when needed, saving on gas costs

<img width="1381" alt="image" src="https://github.com/user-attachments/assets/1148d79d-5f73-4def-873f-bd5daade6aea" />


## 🏗️ Architecture

### Core Contracts

#### `VaultBenji.sol`
- **Purpose**: Manages user deposits and staking
- **Functionality**: 
  - Accepts AVAX deposits
  - Stakes AVAX into Benqi's sAVAX protocol
  - Tracks total balance and rewards
  - Handles withdrawals and winner payouts

#### `Raffle.sol`
- **Purpose**: Manages the raffle system
- **Functionality**:
  - Sells raffle tickets (1 AVAX per ticket)
  - Manages ticket ownership and validity
  - Integrates with Chainlink VRF for winner selection
  - Handles raffle state management

#### `RandomProvider.sol`
- **Purpose**: Chainlink VRF integration
- **Functionality**:
  - Requests random numbers from Chainlink VRF
  - Stores random values for raffle selection
  - Ensures fair and verifiable randomness

#### `DailyTask.sol`
- **Purpose**: Chainlink Automation for daily raffles
- **Functionality**:
  - Checks if raffle should start (every 24 hours)
  - Automatically triggers raffle start
  - Pausable for maintenance

#### `DailyPickWinner.sol`
- **Purpose**: Chainlink Automation for winner selection
- **Functionality**:
  - Checks if winner can be picked
  - Automatically calls winner selection
  - Handles gas-efficient execution

## 🚀 How It Works

### 1. **Deposit & Save**
Users deposit AVAX into the protocol by purchasing raffle tickets (1 AVAX per ticket). Their funds are automatically staked in Benqi's sAVAX protocol to earn staking rewards.

### 2. **Daily Raffles**
Every 24 hours, Chainlink Automation triggers a new raffle:
- All valid tickets enter the raffle
- Chainlink VRF provides verifiable randomness
- One lucky winner is selected

### 3. **Reward Distribution**
The winner receives all accumulated staking rewards from the vault, while all participants keep their original deposits intact.

### 4. **Withdrawal Option**
Users can withdraw their tickets (and get their AVAX back) at any time before a raffle starts, making it truly no-loss.

## 🛡️ Security Features

- **No-Loss Guarantee**: Users never lose their principal
- **Verifiable Randomness**: Chainlink VRF ensures fair winner selection
- **Automated Execution**: Chainlink Automation removes human intervention
- **Time-Locked Tickets**: Tickets must be held for 24 hours to be valid
- **Owner Controls**: Emergency pause and configuration functions

## 📊 Deployed Contracts (Fuji Testnet)

### Core Protocol
- **Vault**: [`0x4b4F492f574ABA2e2cA142f788d96613Abd165eB`](https://testnet.snowtrace.io/address/0x4b4F492f574ABA2e2cA142f788d96613Abd165eB/contract/43113/code)
- **Raffle**: [`0x4C3B188b2DF090592C26eA1850B72dA0c7A749e4`](https://testnet.snowtrace.io/address/0x4C3B188b2DF090592C26eA1850B72dA0c7A749e4)

### Chainlink Integration
- **RandomProvider**: [`0x2cbcA1B2823b4eBC81CA48Cf2aD3f32eDf6BAbC3`](https://testnet.snowtrace.io/address/0x2cbcA1B2823b4eBC81CA48Cf2aD3f32eDf6BAbC3/contract/43113/code)
- **DailyTask (Automation)**: [`0x6B4d0d73F637B82FD8f5B95fea5CaDf343E2f220`](https://testnet.snowtrace.io/address/0x6B4d0d73F637B82FD8f5B95fea5CaDf343E2f220/contract/43113/code)
- **DailyPickWinner (Automation)**: [`0x55Bdc71C2D7EcEEF609C5871AC9D06326626E174`](https://testnet.snowtrace.io/address/0x55Bdc71C2D7EcEEF609C5871AC9D06326626E174/contract/43113/code)

### Mock Contracts
- **Mock Staked AVAX**: [`0x7670BE37c93037E8D6901b4d9B10bb8E3b83c15B`](https://testnet.snowtrace.io/address/0x7670BE37c93037E8D6901b4d9B10bb8E3b83c15B/contract/43113/code)

### Chainlink VRF Subscription
- **VRF Subscription**: [`0x62fbcb63f5f0eec81d46097fc568d140c48df16e93c632c5cb983ae680a7f160`](https://testnet.snowtrace.io/tx/0x62fbcb63f5f0eec81d46097fc568d140c48df16e93c632c5cb983ae680a7f160)

## 🛠️ Development

### Prerequisites
- Foundry
- Node.js
- pnpm

### Setup
```bash
# Install dependencies
pnpm install

# Install Foundry dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test
```

### Deployment
```bash
# Deploy to Fuji testnet
forge script script/FujiDeployKeepers.s.sol --rpc-url $FUJI_RPC_URL --broadcast --verify
```

## 🧪 Testing

The project includes comprehensive tests covering:
- Raffle functionality
- Vault operations
- Chainlink VRF integration
- Automation triggers
- Edge cases and security scenarios

Run tests with:
```bash
forge test -vv
```

## 🎨 Key Features

- ✅ **No-Loss Savings**: Users never lose their principal
- ✅ **Staking Rewards**: Earn through Benqi's sAVAX protocol
- ✅ **Daily Raffles**: Exciting daily winner selection
- ✅ **Chainlink VRF**: Verifiable and fair randomness
- ✅ **Chainlink Automation**: Fully automated execution
- ✅ **Time-Locked Tickets**: Prevents gaming the system
- ✅ **Emergency Controls**: Pausable for maintenance
- ✅ **Gas Efficient**: Optimized for cost-effective operation

## 🏆 Hackathon Requirements Compliance

This project fully complies with the Chromion hackathon requirements:

- ✅ **Chainlink Integration**: Uses both Chainlink VRF and Chainlink Automation
- ✅ **State Changes**: Makes blockchain state changes through automated raffles
- ✅ **Innovative Use Case**: Novel no-loss saving protocol with gamification
- ✅ **Production Ready**: Comprehensive testing and security considerations

## 🤝 Contributing

This project was built for the Chromion hackathon. Feel free to explore the code and provide feedback!

## 📄 License

This project is licensed under the MIT License.

---

**Built with ❤️ for the Chromion Hackathon using Chainlink's powerful oracle network!**
