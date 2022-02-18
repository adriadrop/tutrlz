const hre = require("hardhat");
const ethers = hre.ethers;


function saveSVG(tokenid, data) {
  const fs = require("fs");
  const svgDir = __dirname + "/../svgs";

  if (!fs.existsSync(svgDir)) {
    fs.mkdirSync(svgDir);
  }

  fs.writeFileSync(
    svgDir + "/" + tokenid + ".svg",
    data
  );


}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await hre.run("compile");

  // We get the contract to deploy
  const Turtles = await hre.ethers.getContractFactory("TinyWingedTurtlez");
  const turtles = await Turtles.deploy(
    "0x58807baD0B376efc12F5AD86aAc70E78ed67deaE"
  );

  await turtles.deployed();

  console.log("Greeter deployed to:", turtles.address);
  console.log("Greeter deployed to:", await turtles.name());

  await turtles.mint(4, { value: ethers.utils.parseEther("1.0") });
  await turtles.tokenURI(4).then((res) => {
    //do something with res here
    uri = res.split(",")[1];

    // Parse to JSON
    const json_uri = Buffer.from(uri, "base64").toString("utf-8");
    image = JSON.parse(json_uri)["image"];

    // Parse to SVG
    image = image.split(",")[1];
    const image_svg = Buffer.from(image, "base64").toString("utf-8");

    console.log(image_svg);

    saveSVG(4, image_svg);
    //  process.exit();
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
