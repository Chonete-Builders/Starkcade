"use client";

import React, { useCallback, useRef, useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { Bars3Icon, CircleStackIcon } from "@heroicons/react/24/outline";
import { useOutsideClick } from "~~/hooks/scaffold-stark";
import { CustomConnectButton } from "~~/components/scaffold-stark/CustomConnectButton";
import { usePathname } from "next/navigation";
import StarryBackground from "../components/starryBackground/_components/StarryBackground";

type HeaderMenuLink = {
  label: string;
  href: string;
  icon?: React.ReactNode;
};

export const menuLinks: HeaderMenuLink[] = [
  {
    label: "Home",
    href: "/",
  },
  {
    label: "Coinflip",
    href: "/coinflip",
    icon: <CircleStackIcon className="h-4 w-4" />,
  },
  {
    label: "Recentflips",
    href: "/recentflips",
    icon: <CircleStackIcon className="h-4 w-4" />,
  },
];

export const HeaderMenuLinks = () => {
  const pathname = usePathname();

  return (
    <>
      {menuLinks.map(({ label, href, icon }) => {
        const isActive = pathname === href;
        return (
          <li key={href}>
            <Link
              href={href}
              className={`${
                isActive
                  ? "!bg-gradient-nav !text-white active:bg-gradient-nav shadow-md"
                  : ""
              } py-1.5 px-2 text-sm flex items-center gap-2 hover:bg-gradient-nav hover:text-white`}
            >
              {icon}
              <span>{label}</span>
            </Link>
          </li>
        );
      })}
    </>
  );
};


export const Header = () => {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const burgerMenuRef = useRef<HTMLDivElement>(null);

  useOutsideClick(
    burgerMenuRef,
    useCallback(() => setIsDrawerOpen(false), []),
  );

  return (
    <div className="relative">
      <StarryBackground />
      <div
        className="relative z-10 top-0 navbar min-h-0 flex-shrink-0 px-4 sm:px-6 lg:px-8 border-b border-yellow-500"
      >
        <div className="flex items-center justify-between w-full">
          <div className="flex items-center gap-4">
            <div className="lg:hidden dropdown" ref={burgerMenuRef}>
              <label
                tabIndex={0}
                className="btn btn-ghost"
                onClick={() => setIsDrawerOpen((prev) => !prev)}
              >
                <Bars3Icon className="h-6 w-6" />
              </label>
              {isDrawerOpen && (
                <ul
                  tabIndex={0}
                  className="menu menu-compact dropdown-content mt-3 p-2 shadow rounded-box w-52 bg-base-100"
                  onClick={() => setIsDrawerOpen(false)}
                >
                  <HeaderMenuLinks />
                </ul>
              )}
            </div>
            <Link href="/" className="hidden lg:flex items-center gap-2">
              <div className="relative w-10 h-10">
                <Image
                  alt="Starkcade logo"
                  className="cursor-pointer"
                  fill
                  src="/starkcade.png"
                />
              </div>
              <span className="font-bold text-lg text-yellow-400">
                Starkcade
              </span>
            </Link>
            <ul className="hidden lg:flex menu menu-horizontal gap-4">
              <HeaderMenuLinks />
            </ul>
          </div>
          <div className="flex ml-auto">
            <CustomConnectButton />
          </div>
        </div>
      </div>
    </div>
  );
};
