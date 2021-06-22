const hre = require('hardhat');
const fs = require('fs');

const { deployAsOwner } = require('../scripts/utils/deployer');

const REGISTRY_ADDR = '0xD6049E1F5F3EfF1F921f5532aF1A1632bA23929C';

const nullAddress = '0x0000000000000000000000000000000000000000';

const ETH_ADDR = '0x3649E46eCD6A0bd187f0046C4C35a7B31C92bA1E';
const HZL_ADDR = '0xc01Ee7f10EA4aF4673cFff62710E1D7792aBa8f3';
const USDT_ADDR = '0xb6F2B9415fc599130084b7F20B84738aCBB15930';
const BTC_ADDR = '0x527FC4060Ac7Bf9Cd19608EDEeE8f09063A16cd4';
const LOGGER_ADDR = '0x5c55B921f590a89C1Ebe84dF170E655a82b62126';

const OWNER_ACC = '0xBc841B0dE0b93205e912CFBBd1D0c160A1ec6F00';
const ADMIN_ACC = '0x25eFA336886C74eA8E282ac466BdCd0199f85BB9';



const getAddrFromRegistry = async (name) => {
    const registryInstance = await hre.ethers.getContractFactory('HZLRegistry');
    const registry = await registryInstance.attach(REGISTRY_ADDR);

    const addr = await registry.getAddr(
        hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes(name)),
    );
    return addr;
};

const getProxyWithSigner = async (signer, addr) => {
    const proxyRegistry = await
    hre.ethers.getContractAt('IProxyRegistry', '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4');

    let proxyAddr = await proxyRegistry.proxies(addr);

    if (proxyAddr === nullAddress) {
        await proxyRegistry.build(addr);
        proxyAddr = await proxyRegistry.proxies(addr);
    }

    const dsProxy = await hre.ethers.getContractAt('IHZLProxy', proxyAddr, signer);

    return dsProxy;
};

const getProxy = async (acc) => {
    const proxyRegistry = await
    hre.ethers.getContractAt('IProxyRegistry', '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4');

    let proxyAddr = await proxyRegistry.proxies(acc);

    if (proxyAddr === nullAddress) {
        await proxyRegistry.build(acc);
        proxyAddr = await proxyRegistry.proxies(acc);
    }

    const dsProxy = await hre.ethers.getContractAt('IHZLProxy', proxyAddr);

    return dsProxy;
};

const redeploy = async (name, regAddr = REGISTRY_ADDR) => {
    if (regAddr === REGISTRY_ADDR) {
        await impersonateAccount(OWNER_ACC);
    }

    const signer = await hre.ethers.provider.getSigner(OWNER_ACC);

    const registryInstance = await hre.ethers.getContractFactory('HZLRegistry', signer);
    const registry = await registryInstance.attach(regAddr);

    registry.connect(signer);

    const c = await deployAsOwner(name);
    const id = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes(name));

    if (!(await registry.isRegistered(id))) {
        await registry.addNewContract(id, c.address, 0, { gasLimit: 2000000 });
    } else {
        await registry.startContractChange(id, c.address);
        await registry.approveContractChange(id);
    }

    if (regAddr === REGISTRY_ADDR) {
        await stopImpersonatingAccount(OWNER_ACC);
    }
    return c;
};

const send = async (tokenAddr, to, amount) => {
    const tokenContract = await hre.ethers.getContractAt('IERC20', tokenAddr);

    await tokenContract.transfer(to, amount);
};

const approve = async (tokenAddr, to) => {
    const tokenContract = await hre.ethers.getContractAt('IERC20', tokenAddr);

    const allowance = await tokenContract.allowance(tokenContract.signer.address, to);

    if (allowance.toString() === '0') {
        await tokenContract.approve(to, hre.ethers.constants.MaxUint256, { gasLimit: 1000000 });
    }
};

const sendEther = async (signer, to, amount) => {
    const value = hre.ethers.utils.parseUnits(amount, 18);
    const txObj = await signer.populateTransaction({ to, value, gasLimit: 300000 });

    await signer.sendTransaction(txObj);
};

const balanceOf = async (tokenAddr, addr) => {
    const tokenContract = await hre.ethers.getContractAt('IERC20', tokenAddr);

    let balance = '';

    if (tokenAddr.toLowerCase() === '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee') {
        balance = await hre.ethers.provider.getBalance(addr);
    } else {
        balance = await tokenContract.balanceOf(addr);
    }

    return balance;
};

const formatExchangeObj = (srcAddr, destAddr, amount, wrapper, destAmount = 0, uniV3fee) => {
    const abiCoder = new hre.ethers.utils.AbiCoder();

    let firstPath = srcAddr;
    let secondPath = destAddr;

    if (srcAddr.toLowerCase() === '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee') {
        firstPath = WETH_ADDRESS;
    }

    if (destAddr.toLowerCase() === '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee') {
        secondPath = WETH_ADDRESS;
    }

    let path = abiCoder.encode(['address[]'], [[firstPath, secondPath]]);
    if (uniV3fee > 0) {
        if (destAmount > 0) {
            path = hre.ethers.utils.solidityPack(['address', 'uint24', 'address'], [secondPath, uniV3fee, firstPath]);
        } else {
            path = hre.ethers.utils.solidityPack(['address', 'uint24', 'address'], [firstPath, uniV3fee, secondPath]);
        }
    }
    return [
        srcAddr,
        destAddr,
        amount,
        destAmount,
        0,
        0,
        nullAddress,
        wrapper,
        path,
        [nullAddress, nullAddress, nullAddress, 0, 0, hre.ethers.utils.toUtf8Bytes('')],
    ];
};

const isEth = (tokenAddr) => {
    if (tokenAddr.toLowerCase() === ETH_ADDR.toLowerCase()
    || tokenAddr.toLowerCase() === WETH_ADDRESS.toLowerCase()
    ) {
        return true;
    }

    return false;
};

const convertToWeth = (tokenAddr) => {
    if (isEth(tokenAddr)) {
        return WETH_ADDRESS;
    }

    return tokenAddr;
};

const setNewExchangeWrapper = async (acc, newAddr) => {
    const exchangeOwnerAddr = '0xBc841B0dE0b93205e912CFBBd1D0c160A1ec6F00';
    await sendEther(acc, exchangeOwnerAddr, '1');
    await impersonateAccount(exchangeOwnerAddr);

    const signer = await hre.ethers.provider.getSigner(exchangeOwnerAddr);

    const registryInstance = await hre.ethers.getContractFactory('SaverExchangeRegistry');
    const registry = await registryInstance.attach('0x25dd3F51e0C3c3Ff164DDC02A8E4D65Bb9cBB12D');
    const registryByOwner = registry.connect(signer);

    await registryByOwner.addWrapper(newAddr, { gasLimit: 300000 });
    await stopImpersonatingAccount(exchangeOwnerAddr);
};

const depositToWeth = async (amount) => {
    const weth = await hre.ethers.getContractAt('IWETH', WETH_ADDRESS);

    await weth.deposit({ value: amount });
};

const timeTravel = async (timeIncrease) => {
    await hre.network.provider.request({
        method: 'evm_increaseTime',
        params: [timeIncrease],
        id: new Date().getTime(),
    });
};

const BN2Float = (bn, decimals) => hre.ethers.utils.formatUnits(bn, decimals);

const Float2BN = (string, decimals) => hre.ethers.utils.parseUnits(string, decimals);

module.exports = {
    getAddrFromRegistry,
    getProxy,
    getProxyWithSigner,
    redeploy,
    send,
    approve,
    balanceOf,
    formatExchangeObj,
    isEth,
    sendEther,
    impersonateAccount,
    stopImpersonatingAccount,
    convertToWeth,
    depositToWeth,
    timeTravel,
    fetchStandardAmounts,
    setNewExchangeWrapper,
    fetchAmountinUSDPrice,
    standardAmounts,
    nullAddress,
    dydxTokens,
    REGISTRY_ADDR,
    AAVE_MARKET,
    DAI_ADDR,
    KYBER_WRAPPER,
    UNISWAP_WRAPPER,
    OASIS_WRAPPER,
    WETH_ADDRESS,
    ETH_ADDR,
    OWNER_ACC,
    ADMIN_ACC,
    USDC_ADDR,
    AAVE_FL_FEE,
    MIN_VAULT_DAI_AMOUNT,
    MIN_VAULT_RAI_AMOUNT,
    RAI_ADDR,
    MAX_UINT,
    MAX_UINT128,
    LOGGER_ADDR,
    UNIV3ROUTER_ADDR,
    UNIV3POSITIONMANAGER_ADDR,
    BN2Float,
    Float2BN,
    YEARN_REGISTRY_ADDRESS,
    STETH_ADDRESS,
};
