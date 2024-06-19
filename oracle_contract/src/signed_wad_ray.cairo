// Signed Wad/Ray implementation based on alexandria implementation : https://github.com/keep-starknet-strange/alexandria/blob/main/packages/math/src/wad_ray_math.cairo

// use core::fmt::{Display, Formatter, Error};

// fn is_positive(x : @i128) -> bool {
//     *x >= 0_i128
// }
// fn unsigned(x: @i128) -> u128 {
// }
// fn abs(i128) -> @i128 {
//     if 
// }
// fn into_signed(u128) -> i128{

// }

// impl I128Div of Div<i128> {
//     fn div(lhs: i128, rhs: i128) -> i128 {
//         // bool lhs_positive
//         // bool rhs_positive

//         0_i128
//     }
// }

// impl I128Display of Display<i128> {
//     fn fmt(self: @i128, ref f: Formatter) -> Result<(), Error> {
//         let positive = *self >= 0_i128;
//         let sign : ByteArray = if positive { "" } else { "-" };
//         let value : u128 = if positive {
//             (*self).try_into().unwrap()
//         } else {
//             (-1_i128 * *self).try_into().unwrap()
//         };

//         write!(f, "{}{}", sign, value)
//     }
// }

// /// Provides functions to perform calculations with Wad and Ray units
// /// @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
// /// with 27 digits of precision)
// /// Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
// /// https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/WadRayMath.sol

// pub(crate) const WAD: i128 = 1_000_000_000_000_000_000; // 1e18
// pub(crate) const HALF_WAD: i128 = 500_000_000_000_000_000; // 0.5e18
// pub(crate) const RAY: i128 = 1_000_000_000_000_000_000_000_000_000; // 1e27
// pub(crate) const HALF_RAY: i128 = 500_000_000_000_000_000_000_000_000; // 0.5e27
// pub(crate) const WAD_RAY_RATIO: i128 = 1_000_000_000; // 1e9
// pub(crate) const HALF_WAD_RAY_RATIO: i128 = 500_000_000; // 0.5e9

// /// Return the wad value
// /// # Returns
// /// * `i128` - The value
// pub fn wad() -> i128 {
//     return WAD;
// }

// /// Return the ray value
// /// # Returns
// /// * `i128` - The value
// pub fn ray() -> i128 {
//     return RAY;
// }

// /// Return the half wad value
// /// # Returns
// /// * `i128` - The value
// pub fn half_wad() -> i128 {
//     return HALF_WAD;
// }

// /// Return the half ray value
// /// # Returns
// /// * `i128` - The value
// pub fn half_ray() -> i128 {
//     return HALF_RAY;
// }


// /// Multiplies two wad, rounding half up to the nearest wad
// /// # Arguments
// /// * a Wad
// /// * b Wad
// /// # Returns
// /// * a*b, in wad
// pub fn wad_mul(a: i128, b: i128) -> i128 {
//     return (a * b + HALF_WAD) / WAD;
// }

// /// Divides two wad, rounding half up to the nearest wad
// /// # Arguments
// /// * a Wad
// /// * b Wad
// /// # Returns
// /// * a/b, in wad
// pub fn wad_div(a: i128, b: i128) -> i128 {
//     return (a * WAD + (b / 2)) / b;
// }

// /// Multiplies two ray, rounding half up to the nearest ray
// /// # Arguments
// /// * a Ray
// /// * b Ray
// /// # Returns
// /// * a raymul b
// pub fn ray_mul(a: i128, b: i128) -> i128 {
//     return (a * b + HALF_RAY) / RAY;
// }

// /// Divides two ray, rounding half up to the nearest ray
// /// # Arguments
// /// * a Ray
// /// * b Ray
// /// # Returns
// /// * a raydiv b
// pub fn ray_div(a: i128, b: i128) -> i128 {
//     return (a * RAY + (b / 2)) / b;
// }

// /// Casts ray down to wad
// /// # Arguments
// /// * a Ray
// /// # Returns
// /// * a converted to wad, rounded half up to the nearest wad
// pub fn ray_to_wad(a: i128) -> i128 {
//     return (HALF_WAD_RAY_RATIO + a) / WAD_RAY_RATIO;
// }

// /// Converts wad up to ray
// /// # Arguments
// /// * a Wad
// /// # Returns
// /// * a converted to ray
// pub fn wad_to_ray(a: i128) -> i128 {
//     return a * WAD_RAY_RATIO;
// }