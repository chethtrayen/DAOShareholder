const { deployments, ethers, getNamedAccounts } = require('hardhat');
const { expect } = require('chai');
const eventWatcher = require('./utils/eventWatcher');

describe('DAO shareholder', () => {
    let shareholder;
    const contract = 'shareholder';

    beforeEach(async() => {
        await deployments.fixture(['all']);
        shareholder = await ethers.getContract("DAOTester");
    })

    describe("Shareholder share",  () => {
        it('should return the deployer shares', async () => {
            const share = await shareholder.getShares()
            expect(share).to.be.equals(100);
        })

        it('should return 0 shares', async () => {})
    })

    describe.only("Request share", () => {
        describe("Create request", () => {
            it("should create a request for 50 shares", async () => {
               try{
                   const {deployer} = await getNamedAccounts();
                    shareholder.createRequest(50);
                    await eventWatcher(shareholder, 'RequestShares');
                    shareholder.createRequest(200);
                    await eventWatcher(shareholder, 'RequestShares');
                    const encodedLogs = shareholder.filters.RequestShares();
                    const logs = await shareholder.queryFilter(encodedLogs, -10000);
                    // const [_, shares] = logs[1].args
                    // console.log(shares.toNumber());
                    console.log(logs)


               }
               catch(e){
                   expect(e).to.be.null;
               }
            })

        })
    })
})
