import logo from './logo.svg';
import './App.css';
import { StarknetConfig } from '@starknet-react/core';
import { useAccount } from '@starknet-react/core';

function YourComponent() {
  const { address } = useAccount()

  return <div>gm {address}</div>
}

function App() {
  return (
    <StarknetConfig>
      <YourApp />
    </StarknetConfig>
  );
}

export default App;
