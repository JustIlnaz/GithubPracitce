using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Pawora.Application.DTOs.Products;
using Pawora.Application.Mappings;
using Pawora.Application.Services;
using Pawora.Application.Validators;
using Pawora.Core.Entities;
using Pawora.Core.Enums;
using Pawora.Core.Interfaces;
using Xunit;

namespace Pawora.Application.Tests;

public class ProductServiceTests
{
    private static readonly Guid FoodCategoryId = Guid.Parse("10000000-0000-0000-0000-000000000001");
    private static readonly Guid ToysCategoryId = Guid.Parse("10000000-0000-0000-0000-000000000002");
    private static readonly Guid ShopId = Guid.Parse("20000000-0000-0000-0000-000000000001");
    private static readonly Guid PremiumFoodId = Guid.Parse("30000000-0000-0000-0000-000000000001");
    private static readonly Guid ToyId = Guid.Parse("30000000-0000-0000-0000-000000000002");
    private static readonly Guid BudgetFoodId = Guid.Parse("30000000-0000-0000-0000-000000000003");

    [Fact]
    public async Task GetProductsAsync_FiltersByCategoryAndSearchTogether()
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto
        {
            CategoryId = FoodCategoryId,
            Search = "Premium"
        });

        var product = Assert.Single(result.Data!);
        Assert.Equal(PremiumFoodId, product.Id);
    }

    [Fact]
    public async Task GetProductsAsync_FiltersByMinimumEffectivePriceInclusively()
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto
        {
            MinPrice = 80m,
            SortBy = ProductSortOptions.PriceAscending
        });

        Assert.Equal([PremiumFoodId], result.Data!.Select(product => product.Id));
    }

    [Fact]
    public async Task GetProductsAsync_FiltersByMaximumEffectivePriceInclusively()
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto
        {
            MaxPrice = 70m,
            SortBy = ProductSortOptions.PriceAscending
        });

        Assert.Equal(
            [BudgetFoodId, ToyId],
            result.Data!.Select(product => product.Id));
    }

    [Fact]
    public async Task GetProductsAsync_CombinesCategoryAndPriceRange()
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto
        {
            CategoryId = FoodCategoryId,
            MinPrice = 60m,
            MaxPrice = 80m
        });

        var product = Assert.Single(result.Data!);
        Assert.Equal(PremiumFoodId, product.Id);
    }

    [Theory]
    [InlineData(ProductSortOptions.PriceAscending, "30000000-0000-0000-0000-000000000003", "30000000-0000-0000-0000-000000000002", "30000000-0000-0000-0000-000000000001")]
    [InlineData(ProductSortOptions.PriceDescending, "30000000-0000-0000-0000-000000000001", "30000000-0000-0000-0000-000000000002", "30000000-0000-0000-0000-000000000003")]
    public async Task GetProductsAsync_SortsByEffectivePrice(
        string sortBy,
        string firstId,
        string secondId,
        string thirdId)
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto
        {
            SortBy = sortBy
        });

        Assert.Equal(
            [Guid.Parse(firstId), Guid.Parse(secondId), Guid.Parse(thirdId)],
            result.Data!.Select(product => product.Id));
    }

    [Fact]
    public async Task GetProductsAsync_SortsByRatingDescending()
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto
        {
            SortBy = ProductSortOptions.RatingDescending
        });

        Assert.Equal(
            [ToyId, PremiumFoodId, BudgetFoodId],
            result.Data!.Select(product => product.Id));
    }

    [Fact]
    public async Task GetProductsAsync_SortsPopularityByNonCancelledQuantity()
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto
        {
            SortBy = ProductSortOptions.PopularityDescending
        });

        Assert.Equal(
            [BudgetFoodId, PremiumFoodId, ToyId],
            result.Data!.Select(product => product.Id));
    }

    [Fact]
    public async Task GetProductsAsync_AppliesPaginationAfterFilteringAndSorting()
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto
        {
            MinPrice = 50m,
            SortBy = ProductSortOptions.PriceAscending,
            Skip = 1,
            Take = 1
        });

        var product = Assert.Single(result.Data!);
        Assert.Equal(ToyId, product.Id);
    }

    [Fact]
    public async Task GetProductsAsync_UsesNewestFirstAsDefaultOrder()
    {
        await using var context = await CreateContextAsync();
        var service = CreateService(context);

        var result = await service.GetProductsAsync(new ProductFilterDto());

        Assert.Equal(
            [BudgetFoodId, ToyId, PremiumFoodId],
            result.Data!.Select(product => product.Id));
    }

    [Fact]
    public void ProductFilterValidator_RejectsInvalidRangeAndSortOption()
    {
        var validator = new ProductFilterDtoValidator();

        var result = validator.Validate(new ProductFilterDto
        {
            MinPrice = 100m,
            MaxPrice = 50m,
            SortBy = "unsafe_expression"
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, error => error.ErrorMessage.Contains("Минимальная цена"));
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(ProductFilterDto.SortBy));
    }

    [Theory]
    [InlineData(-1.0, null)]
    [InlineData(null, -1.0)]
    public void ProductFilterValidator_RejectsNegativePrices(double? minPrice, double? maxPrice)
    {
        var validator = new ProductFilterDtoValidator();

        var result = validator.Validate(new ProductFilterDto
        {
            MinPrice = minPrice.HasValue ? (decimal)minPrice.Value : null,
            MaxPrice = maxPrice.HasValue ? (decimal)maxPrice.Value : null
        });

        Assert.False(result.IsValid);
    }

    private static ProductService CreateService(ProductTestDbContext context)
    {
        var mapper = new MapperConfiguration(configuration =>
            configuration.AddProfile<MappingProfile>()).CreateMapper();
        return new ProductService(new TestProductRepository(context), mapper);
    }

    private static async Task<ProductTestDbContext> CreateContextAsync()
    {
        var options = new DbContextOptionsBuilder<ProductTestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        var context = new ProductTestDbContext(options);

        var food = new Category { Id = FoodCategoryId, Name = "Food", SortOrder = 1 };
        var toys = new Category { Id = ToysCategoryId, Name = "Toys", SortOrder = 2 };
        var shop = new Shop
        {
            Id = ShopId,
            Name = "Test shop",
            Address = "Test address",
            OwnerId = Guid.NewGuid()
        };

        var products = new[]
        {
            new Product
            {
                Id = PremiumFoodId,
                Name = "Premium Food",
                Description = "Food for pets",
                Price = 100m,
                DiscountPrice = 80m,
                Category = food,
                CategoryId = food.Id,
                Shop = shop,
                ShopId = shop.Id,
                Stock = 10,
                Rating = 4,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Product
            {
                Id = ToyId,
                Name = "Toy",
                Price = 70m,
                Category = toys,
                CategoryId = toys.Id,
                Shop = shop,
                ShopId = shop.Id,
                Stock = 10,
                Rating = 5,
                CreatedAt = new DateTime(2026, 1, 2, 0, 0, 0, DateTimeKind.Utc)
            },
            new Product
            {
                Id = BudgetFoodId,
                Name = "Budget Food",
                Price = 50m,
                Category = food,
                CategoryId = food.Id,
                Shop = shop,
                ShopId = shop.Id,
                Stock = 10,
                Rating = 3,
                CreatedAt = new DateTime(2026, 1, 3, 0, 0, 0, DateTimeKind.Utc)
            }
        };

        context.AddRange(products);
        AddOrder(context, products[0], quantity: 2, OrderStatus.Delivered);
        AddOrder(context, products[0], quantity: 100, OrderStatus.Cancelled);
        AddOrder(context, products[2], quantity: 5, OrderStatus.InProgress);
        await context.SaveChangesAsync();
        return context;
    }

    private static void AddOrder(
        ProductTestDbContext context,
        Product product,
        int quantity,
        OrderStatus status)
    {
        var order = new Order
        {
            UserId = Guid.NewGuid(),
            Status = status,
            TotalAmount = product.Price * quantity
        };
        order.Items.Add(new OrderItem
        {
            Product = product,
            ProductId = product.Id,
            Quantity = quantity,
            UnitPrice = product.Price
        });
        context.Set<Order>().Add(order);
    }

    private sealed class ProductTestDbContext(
        DbContextOptions<ProductTestDbContext> options) : DbContext(options)
    {
        public DbSet<Product> Products => Set<Product>();
    }

    private sealed class TestProductRepository(ProductTestDbContext context)
        : IRepository<Product>
    {
        public Task<Product?> GetByIdAsync(Guid id)
        {
            return context.Products.FirstOrDefaultAsync(product => product.Id == id);
        }

        public async Task<IReadOnlyList<Product>> GetAllAsync()
        {
            return await context.Products.ToListAsync();
        }

        public IQueryable<Product> Query()
        {
            return context.Products;
        }

        public async Task<Product> AddAsync(Product entity)
        {
            await context.Products.AddAsync(entity);
            return entity;
        }

        public Task UpdateAsync(Product entity)
        {
            context.Products.Update(entity);
            return Task.CompletedTask;
        }

        public Task DeleteAsync(Product entity)
        {
            context.Products.Remove(entity);
            return Task.CompletedTask;
        }

        public Task<int> SaveChangesAsync()
        {
            return context.SaveChangesAsync();
        }
    }
}
