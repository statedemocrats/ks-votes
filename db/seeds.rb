# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

ks_counties = %w(
 Edwards
 Gray
 Logan
 Riley
 Wabaunsee
 Allen
 Anderson
 Atchison
 Barber
 Barton
 Bourbon
 Brown
 Butler
 Chase
 Chautauqua
 Cherokee
 Cheyenne
 Clark
 Clay
 Cloud
 Coffey
 Comanche
 Cowley
 Crawford
 Decatur
 Dickinson
 Doniphan
 Douglas
 Elk
 Ellis
 Ellsworth
 Finney
 Ford
 Franklin
 Geary
 Gove
 Graham
 Grant
 Greeley
 Greenwood
 Hamilton
 Harper
 Harvey
 Haskell
 Hodgeman
 Jackson
 Jefferson
 Jewell
 Johnson
 Kearny
 Kingman
 Kiowa
 Labette
 Lane
 Leavenworth
 Lincoln
 Linn
 Lyon
 Marion
 Marshall
 McPherson
 Meade
 Miami
 Mitchell
 Montgomery
 Morris
 Morton
 Nemaha
 Neosho
 Ness
 Norton
 Osage
 Osborne
 Ottawa
 Pawnee
 Phillips
 Pottawatomie
 Pratt
 Rawlins
 Reno
 Republic
 Rice
 Rooks
 Rush
 Russell
 Saline
 Scott
 Sedgwick
 Seward
 Shawnee
 Sheridan
 Sherman
 Smith
 Stafford
 Stanton
 Stevens
 Sumner
 Thomas
 Trego
 Wallace
 Washington
 Wichita
 Wilson
 Woodson
 Wyandotte
)

ks_counties.each do |cty|
  County.create(name: cty)
end
