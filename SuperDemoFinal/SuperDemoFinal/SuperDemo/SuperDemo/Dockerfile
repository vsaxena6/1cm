FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS base
WORKDIR %%WORKDIR%%
EXPOSE %%EXPOSE%% 

FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build
WORKDIR %%WORKDIR2%% 

COPY [%%CSPROJPATH%%, %%COPY1%%]
RUN dotnet restore %%CSPROJPATH%%
COPY . .
WORKDIR  %%WORKDIR3%%
RUN dotnet build %%APPNAME%% -c Release -o /app/build

FROM build AS publish
RUN dotnet publish %%APPNAME%% -c Release -o /app/publish

FROM base AS final
WORKDIR %%WORKDIR%%
COPY --from=publish /app/publish .
ENTRYPOINT %%ENTRYPOINT%%