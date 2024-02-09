const eth = (n) => {
    return web3.utils.toWei(n, 'ether');
}

const finney = (n) => {
    return web3.utils.toWei(n, 'finney');
}

const finneyInt = (n) => {
    return parseInt(web3.utils.toWei(n, 'finney'));
}

const nullAddress = () => {
    return '0x0000000000000000000000000000000000000000';
}

export default {eth, finney, finneyInt, nullAddress}