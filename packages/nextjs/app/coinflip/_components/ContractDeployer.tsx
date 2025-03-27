"use client";

import { useState, useEffect } from 'react';

const useStarknetEnvironment = () => {
  const [networkInfo, setNetworkInfo] = useState({
    isTestEnvironment: false,
    networkName: '',
    isLoading: true
  });

  useEffect(() => {
    const checkNetwork = async () => {
      try {
        const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
        
        let networkName = '';
        let isTestnet = false;
        
        if (window.starknet) {
          try {
            const chainId = await window.starknet.provider.getChainId();
            
            if (chainId === 'SN_GOERLI' || chainId === 'SN_SEPOLIA') {
              isTestnet = true;
              networkName = chainId === 'SN_GOERLI' ? 'Starknet Goerli' : 'Starknet Sepolia';
            } else if (chainId === 'SN_MAIN') {
              networkName = 'Starknet Mainnet';
            } else {
              networkName = `Starknet Chain: ${chainId}`;
            }
          } catch (error) {
            console.error("Error getting Starknet chain ID:", error);
            networkName = 'Unknown Starknet Network';
          }
        }
        
        setNetworkInfo({
          isTestEnvironment: isLocalhost || isTestnet,
          networkName: networkName || (isLocalhost ? 'Local Development' : 'Unknown Network'),
          isLoading: false
        });
      } catch (error) {
        console.error("Error checking network:", error);
        setNetworkInfo({
          isTestEnvironment: false,
          networkName: 'Error detecting network',
          isLoading: false
        });
      }
    };

    checkNetwork();
    
    if (window.starknet) {
      const handleNetworkChange = () => {
        window.location.reload();
      };
      
      if (window.starknet.on) {
        window.starknet.on('networkChanged', handleNetworkChange);
        
        return () => {
          if (window.starknet && window.starknet.removeListener) {
            window.starknet.removeListener('networkChanged', handleNetworkChange);
          }
        };
      }
    }
  }, []);

  return networkInfo;
};

export const ContractDeployer = () => {
  const { isTestEnvironment, networkName, isLoading } = useStarknetEnvironment();
  const [contractName, setContractName] = useState('');
  const [contractABI, setContractABI] = useState('');
  const [bytecode, setBytecode] = useState('');
  const [deployedAddress, setDeployedAddress] = useState<string | null>(null);
  const [isDeploying, setIsDeploying] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  const deployContract = async () => {
    if (!contractName || !contractABI || !bytecode) return;
    
    setIsDeploying(true);
    
    try {
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const mockAddress = "0x" + Math.random().toString(16).slice(2, 64);
      setDeployedAddress(mockAddress);
      setIsSuccess(true);
    } catch (error) {
      console.error("Deployment failed:", error);
    } finally {
      setIsDeploying(false);
    }
  };

  if (isLoading) {
    return (
      <div className="p-4 bg-base-200 rounded-md text-center">
        <p>Checking Starknet network environment...</p>
      </div>
    );
  }

  if (!isTestEnvironment) {
    return (
      <div className="p-4 bg-yellow-100 text-yellow-800 rounded-md">
        <h3 className="font-bold text-lg mb-2">Restricted Feature</h3>
        <p>Contract deployment is only available on Starknet testnets or local development environments.</p>
        <p className="mt-2">Current network: <span className="font-medium">{networkName}</span></p>
        <p className="mt-4 text-sm">Please switch to a Starknet testnet or a local development environment to access this feature.</p>
      </div>
    );
  }

  return (
    <div className="contract-deployer max-w-3xl mx-auto p-6 bg-base-100 rounded-lg shadow-md">
      <h2 className="text-3xl font-bold mb-4">Smart Contract Management</h2>
      
      <div className="bg-white p-6 rounded-lg shadow-sm">
        <h3 className="text-xl font-bold mb-2">Deploy Smart Contract</h3>
        <p className="text-gray-600 mb-4">Deploy your contract to {networkName}</p>
        
        <div className="bg-yellow-50 border border-yellow-200 p-4 rounded-md mb-6">
          <div className="flex items-start">
            <div className="mr-2 mt-0.5">
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-yellow-800" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2h-1V9z" clipRule="evenodd" />
              </svg>
            </div>
            <div>
              <p className="font-medium text-yellow-800">Test Environment: {networkName}</p>
              <p className="text-yellow-700">You are currently on a Starknet test network. Contracts deployed here will not affect production.</p>
            </div>
          </div>
        </div>
        
        <div className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-1">
              Contract Name
            </label>
            <input
              type="text"
              value={contractName}
              onChange={(e) => setContractName(e.target.value)}
              className="w-full p-2 border rounded bg-white text-gray-800"
              placeholder="MyToken"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">
              Contract ABI
            </label>
            <textarea
              value={contractABI}
              onChange={(e) => setContractABI(e.target.value)}
              className="w-full p-2 border rounded bg-white text-gray-800 font-mono text-sm"
              placeholder='[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"}...]'
              rows={4}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">
              Bytecode
            </label>
            <textarea
              value={bytecode}
              onChange={(e) => setBytecode(e.target.value)}
              className="w-full p-2 border rounded bg-white text-gray-800 font-mono text-sm"
              placeholder="0x608060405234801561001057600080fd5b50..."
              rows={4}
            />
          </div>
          
          <button
            onClick={deployContract}
            disabled={!contractName || !contractABI || !bytecode || isDeploying}
            className="w-full py-3 px-4 bg-gray-500 text-white rounded font-semibold hover:bg-gray-600 disabled:bg-gray-300 transition duration-300"
          >
            {isDeploying ? 'Deploying...' : 'Deploy Contract'}
          </button>
          
          {isSuccess && deployedAddress && (
            <div className="mt-4 p-3 bg-green-100 text-green-800 rounded">
              <p className="font-bold">Contract deployed successfully!</p>
              <p className="text-sm mt-2 break-all">Address: {deployedAddress}</p>
            </div>
          )}
        </div>
      </div>
      
      <div className="text-center mt-8 text-gray-600">
        Connect your Starknet wallet to interact with deployed contracts
      </div>
    </div>
  );
};

export default ContractDeployer;

declare global {
  interface Window {
    starknet?: {
      provider: {
        getChainId: () => Promise<string>;
      };
      on?: (event: string, listener: (...args: any[]) => void) => void;
      removeListener?: (event: string, listener: (...args: any[]) => void) => void;
    };
  }
} 