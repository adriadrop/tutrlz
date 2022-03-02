const hre = require("hardhat");
const ethers = hre.ethers;

function saveSVG(tokenid, data) {
  const fs = require("fs");
  const svgDir = __dirname + "/../svgs";

  //do something with res here
  uri = data.split(",")[1];

  // Parse to JSON
  const json_uri = Buffer.from(uri, "base64").toString("utf-8");
  image = JSON.parse(json_uri)["image"];

  // Parse to SVG
  image = image.split(",")[1];
  const image_svg = Buffer.from(image, "base64").toString("utf-8");

 // console.log(json_uri);

  if (!fs.existsSync(svgDir)) {
    fs.mkdirSync(svgDir);
  }

  fs.writeFileSync(svgDir + "/" + tokenid + ".svg", image_svg);
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await hre.run("compile");

  // We get the contract to deploy
  const Originals = await hre.ethers.getContractFactory("KriptoOG");
  const originals = await Originals.deploy(
    "0x58807baD0B376efc12F5AD86aAc70E78ed67deaE"
  );

  await originals.deployed();

  console.log("Greeter deployed to:", originals.address);
  console.log("Greeter deployed to:", await originals.name());

  await originals.mint(10, { value: ethers.utils.parseEther("1.0") });

  for (let i = 1; i < 10; i++) {
    await originals.tokenURI(i).then((res) =>  saveSVG(i, res));
  }

  //await turtles.tokenURI(1).then((res) => saveSVG(1, res));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
