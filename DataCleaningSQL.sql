--Checking the data is there, imported correctly

Select *
FROM NashvilleHousing

--Standarize date (Sale Date)

---Checking the date:

Select SaleDate
From NashvilleHousing

---It includes date and time, time is irrelevant in this case so we want to remove it

Select SaleDate, CONVERT(Date, SaleDate) as Date_Clean
From NashvilleHousing
Order by 2

--- In Spain we use the dd/MM format instead of MM/dd
--- So here we format our column that way to look at it differently (same data, different presentation)
--- To maintain this format we have to order by first column instead of second,
--- otherwise it will show sales from february (01-02) before january (02-01)

Select SaleDate, FORMAT(CONVERT(Date, SaleDate), 'dd-MM-yyyy') as Date_Clean
From NashvilleHousing
Order by 1

-- Creating a new column with the clean date and adding it to the table to use it later

ALTER TABLE NashvilleHousing
ADD SaleDateClean Date

UPDATE NashvilleHousing
SET SaleDateClean = CONVERT(Date,SaleDate)

--Populate Property Address 

Select PropertyAddress
FROM NashvilleHousing

---We see some of the values are null
---By studying the data, we see that sometimes the same ParcelID appears twice
---In all those cases the address is the same. So each ParcelID can only go with one address
---Now we are going to fill in the null address values, if their ParcelID appears again in the data
---and has an address assigned to it.

--Select *
--FROM NashvilleHousing
--order by ParcelID


--Select ParcelID, PropertyAddress
--FROM NashvilleHousing
--order by ParcelID

Select a.ParcelID, a.PropertyAddress, a.[UniqueID ], b.[UniqueID ]
FROM NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Order by a.ParcelID

---Checking that with this ParcelID information we do have an address to add in every case where it is null

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

---Visualization in a new column of the address we are going to add

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null


---Updating the null values with the correct address

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null


--Breaking both the Property and Owner Adress into separate columns 
--(Address, City and State; currently the information is together in one column)
--Using SUBSTRING

--Select PropertyAddress
--FROM NashvilleHousing

---We see that Address and City are separated by a comma, so we use that to split the column

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM NashvilleHousing

---Now we add both the clean address and city into new columns in our table

ALTER TABLE NashvilleHousing
ADD PropertyAddressClean nvarchar(255)

UPDATE NashvilleHousing
SET PropertyAddressClean  = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertyCity nvarchar(255)

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress))


--Now we are splitting the Owner Adress in Address, City and State
--Using PARSENAME. PARSENAME separates by periods, not commas, so we need to replace the commas by periods
--It also works 'backwards', so position 1 is going to be the las bit of information (State) and 3 the first one (Address)

--SELECT OwnerAddress
--From NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) as OwnerAddressClean,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) as OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) as OwnerState
FROM NashvilleHousing

---Now we add this newly split data into columns in our table

ALTER TABLE NashvilleHousing
ADD OwnerAddressClean nvarchar(255)

UPDATE NashvilleHousing
SET OwnerAddressClean  = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerCity nvarchar(255)

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerState nvarchar(255)

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

--Changing the 'y' and 'n' to 'yes' and 'no' in the SoldAsVacant column
--Right now, as we can see below, we have four values there: Yes, No, Y and N. We only need two (Y and N or Yes and No).
--Since 'Yes' and 'No' are the more populated ones according to the count, we will add Y and N to them

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From NashvilleHousing
Group by SoldAsVacant
Order by 2

Select SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM NashvilleHousing

---Update SoldAsVacant column with all Yes or No values

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END


--Removing duplicates from our table
--Note: Permanently deleting existing data is usually not standard procedure

---Using a CTE and the ROW_NUMBER function

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) as row_num
From NashvilleHousing
)

---In cases where two or more rows have the same values in all partitions we established, 
---row_num is going to be 2, 3... and all of those are duplicates.

Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

---Now we delete them:

DELETE
From RowNumCTE
Where row_num > 1



--Deleting unused columns 
--Useful for creating visualizations
--Note: this is only for learning purposes. Never delete from raw data


--I duplicated my NasvhilleHousing table to delete the columns from this second table

SELECT *
INTO NashvilleHousing2
FROM NashvilleHousing

ALTER TABLE NashvilleHousing2
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


